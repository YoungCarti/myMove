import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

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
        overlappingSnapshot.forEach((doc) => {
          const bookingStart = new Date(doc.data().startDateTime);
          if (bookingStart < end) {
            overlappingCount++;
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
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        transaction.set(newBookingRef, bookingData);

        return {
          success: true,
          bookingId: newBookingRef.id,
          price: calculatedPrice,
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

