import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

const VALID_SPOT_IDS = new Set([
  "A1", "A2", "A3", "A4", "A5", "A6", "A7",
  "B1", "B2", "B3", "B4", "B5", "B6", "B7",
]);
const MAX_SELECTABLE_SPOTS = VALID_SPOT_IDS.size;

/**
 * Get effective capacity.
 * @param {unknown} rawCapacity Raw capacity
 * @return {number} Effective capacity
 */
function getEffectiveCapacity(rawCapacity: unknown): number {
  const numericCapacity = typeof rawCapacity === "number" ? rawCapacity : 0;
  return Math.min(
    Math.max(Math.floor(numericCapacity), 0),
    MAX_SELECTABLE_SPOTS
  );
}

/**
 * Get username matches.
 * @param {string} trimmed Trimmed username
 * @param {string} cleaned Cleaned username
 * @return {Promise<admin.firestore.QueryDocumentSnapshot[]>} Matches
 */
async function getUsernameMatches(trimmed: string, cleaned: string) {
  const usersRef = db.collection("users");
  const [lowercaseSnapshot, legacySnapshot] = await Promise.all([
    usersRef.where("username_lowercase", "==", cleaned).limit(1).get(),
    usersRef.where("username", "==", trimmed).limit(1).get(),
  ]);

  const matches = new Map<string, admin.firestore.QueryDocumentSnapshot>();
  lowercaseSnapshot.docs.forEach((doc) => matches.set(doc.id, doc));
  legacySnapshot.docs.forEach((doc) => matches.set(doc.id, doc));
  return Array.from(matches.values());
}

// Safely resolve a username to an email address without exposing
// user documents to unauthenticated clients.
export const lookupUsername = onCall(
  {enforceAppCheck: false, invoker: "public"},
  async (request) => {
    const {username} = request.data;
    if (!username || typeof username !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "A username string is required."
      );
    }

    let cleaned = username.trim().toLowerCase();
    if (cleaned.startsWith("@")) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Please enter a valid username."
      );
    }

    const matches = await getUsernameMatches(username.trim(), cleaned);

    if (matches.length === 0) {
      throw new HttpsError(
        "not-found",
        `No user found with the username "@${cleaned}".`
      );
    }

    const userData = matches[0].data();
    const email = userData.email as string | undefined;
    if (!email) {
      throw new HttpsError(
        "not-found",
        "This username does not have a registered email address."
      );
    }

    // Only return the email — never expose other profile fields
    return {email};
  }
);

// Check if a username is available. Authenticated users only.
export const checkUsernameAvailable = onCall(
  {enforceAppCheck: false, invoker: "public"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to check username availability."
      );
    }

    const {username} = request.data;
    if (!username || typeof username !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "A username string is required."
      );
    }

    const trimmed = username.trim();
    const cleaned = trimmed.toLowerCase();
    if (cleaned.length === 0) {
      return {available: false};
    }

    const matches = await getUsernameMatches(trimmed, cleaned);

    if (matches.length === 0) {
      return {available: true};
    }

    // If every match is the requesting user, it's still available. This
    // keeps legacy profiles without username_lowercase from being duplicated.
    const isOwnUsername = matches.every((doc) => doc.id === request.auth?.uid);

    return {available: isOwnUsername};
  }
);

export const createBooking = onCall(
  {enforceAppCheck: false, invoker: "public"},
  async (request) => {
    // Authentication check
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to create a booking."
      );
    }

    const userId = request.auth.uid;
    const {locationId, locationName, vehicleMake, vehiclePlate,
      startDateTime, endDateTime} = request.data;

    // Input validation
    if (!locationId || !locationName || !startDateTime || !endDateTime) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required booking parameters."
      );
    }

    const start = new Date(startDateTime);
    const end = new Date(endDateTime);

    if (start >= end) {
      throw new HttpsError(
        "invalid-argument",
        "Start time must be before end time."
      );
    }

    if (start < new Date()) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot book a time in the past."
      );
    }

    // Price calculation
    const diffMilliseconds = end.getTime() - start.getTime();
    let hours = Math.ceil(diffMilliseconds / (1000 * 60 * 60));
    if (hours < 1) hours = 1;

    const locationRef = db.collection("parking_locations").doc(locationId);

    try {
      return await db.runTransaction(async (transaction) => {
        // 1. Read location for capacity and price
        const locationDoc = await transaction.get(locationRef);
        if (!locationDoc.exists) {
          throw new HttpsError(
            "not-found",
            "Parking location not found."
          );
        }

        const locationData = locationDoc.data();
        const totalCapacity = getEffectiveCapacity(
          locationData?.availableSpots
        );

        // Price calculation using the location's stored hourly rate
        const hourlyRate = locationData?.pricePerHour ?? 2.0;
        const calculatedPrice = hours * hourlyRate;

        // 2. Read overlapping bookings
        const overlappingQuery = db.collection("bookings")
          .where("locationId", "==", locationId)
          .where("status", "==", "active")
          .where("endDateTime", ">", startDateTime);

        const overlappingSnapshot = await transaction.get(overlappingQuery);

        let overlappingCount = 0;
        const occupiedSpots: string[] = [];
        overlappingSnapshot.forEach((doc) => {
          const bookingStart = new Date(doc.data().startDateTime);
          if (bookingStart < end) {
            overlappingCount++;
            const spot = doc.data().spotId;
            if (spot) {
              occupiedSpots.push(spot);
            }
          }
        });

        if (overlappingCount >= totalCapacity) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, this parking location is sold out for the selected time."
          );
        }

        // 3. Create booking
        const taxRate = 0.02;
        const taxAmount = calculatedPrice * taxRate;
        const totalPaid = calculatedPrice + taxAmount;

        const newBookingRef = db.collection("bookings").doc();
        const bookingData = {
          userId: userId,
          locationId: locationId,
          locationName: locationName,
          vehicleMake: vehicleMake || null,
          vehiclePlate: vehiclePlate || null,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          calculatedHours: hours,
          totalPrice: calculatedPrice, // Legacy field
          subtotal: calculatedPrice,
          taxRate: taxRate,
          taxAmount: taxAmount,
          totalPaid: totalPaid,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 15 * 60 * 1000)
          ),
        };

        transaction.set(newBookingRef, bookingData);

        return {
          success: true,
          bookingId: newBookingRef.id,
          price: calculatedPrice,
          occupiedSpots: occupiedSpots,
        };
      });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
      // Re-throw HttpsErrors so the client receives the proper status
      // code/message
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("Booking transaction failed:", error);
      throw new HttpsError(
        "internal",
        error.message || "Booking failed."
      );
    }
  }
);

export const assignSpot = onCall(
  {enforceAppCheck: false, invoker: "public"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to assign a spot."
      );
    }

    const {bookingId, spotId} = request.data;
    if (typeof bookingId !== "string" || typeof spotId !== "string" ||
      bookingId.trim().length === 0 || spotId.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Missing bookingId or spotId."
      );
    }

    const requestedSpotId = spotId.trim().toUpperCase();
    if (!VALID_SPOT_IDS.has(requestedSpotId)) {
      throw new HttpsError(
        "invalid-argument",
        "Please select a valid parking spot."
      );
    }

    const bookingRef = db.collection("bookings").doc(bookingId);

    try {
      return await db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }

        const bookingData = bookingDoc.data();
        if (!bookingData) {
          throw new HttpsError("not-found", "Booking data is missing.");
        }
        if (bookingData.userId !== request.auth?.uid) {
          throw new HttpsError("permission-denied", "Not your booking.");
        }

        // P2 FIX: Reject expired pending bookings before activation.
        // Firestore TTL deletion is async and can lag, so a booking
        // past its expiresAt could still exist. Check it explicitly.
        if (bookingData.status !== "pending") {
          throw new HttpsError(
            "failed-precondition",
            "This booking is no longer pending."
          );
        }

        if (bookingData.expiresAt) {
          const expiresAtDate = bookingData.expiresAt.toDate ?
            bookingData.expiresAt.toDate() :
            new Date(bookingData.expiresAt);
          if (expiresAtDate <= new Date()) {
            throw new HttpsError(
              "deadline-exceeded",
              "This booking has expired. Please create a new one."
            );
          }
        }

        if (bookingData.spotId) {
          // If already assigned to the same spot, just return success
          if (bookingData.spotId === requestedSpotId) return {success: true};
          throw new HttpsError(
            "already-exists",
            "A spot is already assigned to this booking."
          );
        }

        // 1. Fetch location to get total capacity
        const locationRef = db.collection("parking_locations")
          .doc(bookingData.locationId);
        const locationDoc = await transaction.get(locationRef);
        if (!locationDoc.exists) {
          throw new HttpsError("not-found", "Parking location not found.");
        }
        const totalCapacity = getEffectiveCapacity(
          locationDoc.data()?.availableSpots
        );

        // CONTENTION FIX: Read+write a single location-level lock
        // document. ALL concurrent assignSpot transactions for this
        // location must go through this document, so Firestore OCC
        // will force one to retry if they overlap. This handles:
        //  - Same spot, overlapping intervals with different starts
        //  - Different spots when only one capacity slot remains
        const lockRef = db.collection("location_locks")
          .doc(bookingData.locationId);
        const lockDoc = await transaction.get(lockRef);

        // 2. Check overlapping active bookings for the entire location
        const overlappingQuery = db.collection("bookings")
          .where("locationId", "==", bookingData.locationId)
          .where("status", "==", "active")
          .where("endDateTime", ">", bookingData.startDateTime);

        const overlappingSnapshot = await transaction.get(overlappingQuery);

        const end = new Date(bookingData.endDateTime);

        let isTaken = false;
        let overlappingCount = 0;

        overlappingSnapshot.forEach((doc) => {
          const bStart = new Date(doc.data().startDateTime);
          if (bStart < end) {
            overlappingCount++;
            if (doc.data().spotId === requestedSpotId) {
              isTaken = true;
            }
          }
        });

        if (isTaken) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, this spot is already taken for the selected time."
          );
        }

        if (overlappingCount >= totalCapacity) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, this location is sold out for the selected time."
          );
        }

        // Bump the lock version so any concurrent transaction that
        // read it will be forced to retry by Firestore OCC.
        const currentVersion = lockDoc.exists ?
          (lockDoc.data()?.version ?? 0) :
          0;
        transaction.set(lockRef, {
          version: currentVersion + 1,
          lastBookingId: bookingId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.update(bookingRef, {
          spotId: requestedSpotId,
          status: "active",
          expiresAt: admin.firestore.FieldValue.delete(),
        });
        return {success: true};
      });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
      if (error instanceof HttpsError) throw error;
      console.error("Assign spot failed:", error);
      throw new HttpsError(
        "internal",
        error.message || "Failed to assign spot."
      );
    }
  }
);

export const cancelBooking = onCall(
  {enforceAppCheck: false},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to cancel a booking."
      );
    }
    const {bookingId} = request.data;
    if (!bookingId || typeof bookingId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "A valid bookingId is required."
      );
    }

    const bookingRef = db.collection("bookings").doc(bookingId);

    try {
      await db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }

        const bookingData = bookingDoc.data();
        if (bookingData?.userId !== request.auth?.uid) {
          throw new HttpsError(
            "permission-denied",
            "You can only cancel your own bookings."
          );
        }

        if (
          bookingData?.status === "canceled" ||
          bookingData?.status === "completed"
        ) {
          throw new HttpsError(
            "failed-precondition",
            "This booking cannot be canceled."
          );
        }

        transaction.update(bookingRef, {
          status: "canceled",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      return {success: true};
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
      if (error instanceof HttpsError) throw error;
      console.error("Cancel booking failed:", error);
      throw new HttpsError(
        "internal",
        error.message || "Failed to cancel booking."
      );
    }
  }
);

export const extendParking = onCall(
  {enforceAppCheck: false, invoker: "public"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to extend parking."
      );
    }

    const {bookingId, extendMinutes, amount, totalPaidIncrease} = request.data;
    if (
      !bookingId ||
      typeof extendMinutes !== "number" ||
      typeof amount !== "number" ||
      typeof totalPaidIncrease !== "number"
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required parameters for extending parking."
      );
    }

    const bookingRef = db.collection("bookings").doc(bookingId);

    try {
      return await db.runTransaction(async (transaction) => {
        const bookingDoc = await transaction.get(bookingRef);
        if (!bookingDoc.exists) {
          throw new HttpsError("not-found", "Booking not found.");
        }

        const bookingData = bookingDoc.data();
        if (!bookingData) {
          throw new HttpsError("not-found", "Booking data is missing.");
        }
        if (bookingData.userId !== request.auth?.uid) {
          throw new HttpsError("permission-denied", "Not your booking.");
        }

        const currentEnd = new Date(bookingData.endDateTime);
        const newEnd = new Date(currentEnd.getTime() + extendMinutes * 60000);

        // Fetch location to get total capacity
        const locId = bookingData.locationId;
        const locationRef = db.collection("parking_locations").doc(locId);
        const locationDoc = await transaction.get(locationRef);
        if (!locationDoc.exists) {
          throw new HttpsError("not-found", "Parking location not found.");
        }
        const spots = locationDoc.data()?.availableSpots;
        const totalCapacity = getEffectiveCapacity(spots);

        const lockRef = db.collection("location_locks").doc(locId);
        const lockDoc = await transaction.get(lockRef);

        // Check overlapping active bookings for the extension period
        const overlappingQuery = db.collection("bookings")
          .where("locationId", "==", locId)
          .where("status", "==", "active")
          .where("endDateTime", ">", currentEnd.toISOString());

        const overlappingSnapshot = await transaction.get(overlappingQuery);

        let isTaken = false;
        let overlappingCount = 0;

        overlappingSnapshot.forEach((doc) => {
          if (doc.id === bookingId) return; // Skip current booking

          const bStart = new Date(doc.data().startDateTime);
          if (bStart < newEnd) {
            overlappingCount++;
            const docSpot = doc.data().spotId;
            if (bookingData.spotId && docSpot === bookingData.spotId) {
              isTaken = true;
            }
          }
        });

        if (isTaken) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, your spot is already booked for the extended time."
          );
        }

        if (overlappingCount >= totalCapacity) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, this location is sold out for the extended time."
          );
        }

        const currentVersion = lockDoc.exists ?
          (lockDoc.data()?.version ?? 0) : 0;

        transaction.set(lockRef, {
          version: currentVersion + 1,
          lastBookingId: bookingId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const currentPrice = bookingData.totalPrice ?? 0;
        const currentTotalPaid = bookingData.totalPaid ?? currentPrice * 1.02;

        const currentCalculatedHours = bookingData.calculatedHours ?? 0;

        transaction.update(bookingRef, {
          endDateTime: newEnd.toISOString(),
          calculatedHours: currentCalculatedHours + (extendMinutes / 60),
          totalPrice: currentPrice + amount,
          totalPaid: currentTotalPaid + totalPaidIncrease,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {success: true};
      });
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
      if (error instanceof HttpsError) throw error;
      console.error("Extend parking failed:", error);
      throw new HttpsError(
        "internal",
        error.message || "Failed to extend parking."
      );
    }
  }
);
