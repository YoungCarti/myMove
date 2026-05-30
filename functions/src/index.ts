import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

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

    const snapshot = await db.collection("users")
      .where("username_lowercase", "==", cleaned)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new HttpsError(
        "not-found",
        `No user found with the username "@${cleaned}".`
      );
    }

    const userData = snapshot.docs[0].data();
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

    const cleaned = username.trim().toLowerCase();
    if (cleaned.length === 0) {
      return {available: false};
    }

    const snapshot = await db.collection("users")
      .where("username_lowercase", "==", cleaned)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return {available: true};
    }

    // If the only match is the requesting user, it's still available
    const isOwnUsername =
      snapshot.docs.length === 1 &&
      snapshot.docs[0].id === request.auth.uid;

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
        const totalCapacity = locationData?.availableSpots ?? 0;

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
          totalPrice: calculatedPrice,
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
    if (!bookingId || !spotId) {
      throw new HttpsError(
        "invalid-argument",
        "Missing bookingId or spotId."
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
          if (bookingData.spotId === spotId) return {success: true};
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
        const totalCapacity = locationDoc.data()?.availableSpots ?? 0;

        // P1 FIX: Read a spot lock document to create transactional
        // contention. Two concurrent assignSpot calls for the same
        // spot+location+time will both read this doc, then one write
        // will win and the other will be forced to retry by Firestore
        // OCC, at which point the retry will see the spot is taken.
        const lockId =
          `${bookingData.locationId}_${spotId}_` +
          `${bookingData.startDateTime}`;
        const lockRef = db.collection("spot_locks").doc(lockId);
        const lockDoc = await transaction.get(lockRef);

        if (lockDoc.exists) {
          throw new HttpsError(
            "resource-exhausted",
            "Sorry, this spot is already taken for the selected time."
          );
        }

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
            if (doc.data().spotId === spotId) {
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

        // Write the lock doc so any concurrent transaction retries
        // and sees it exists, then gets rejected above.
        transaction.set(lockRef, {
          bookingId: bookingId,
          locationId: bookingData.locationId,
          spotId: spotId,
          startDateTime: bookingData.startDateTime,
          endDateTime: bookingData.endDateTime,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.update(bookingRef, {
          spotId,
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
