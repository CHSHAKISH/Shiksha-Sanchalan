const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

// Function 1: Triggers when a new duty is created.
exports.sendDutyNotification = onDocumentCreated("duties/{dutyId}", async (event) => {
  const dutyData = event.data.data();
  const facultyId = dutyData.facultyId;

  if (!facultyId) {
    return console.log("No faculty ID found.");
  }

  try {
    const userDoc = await admin.firestore().collection("users").doc(facultyId).get();
    if (!userDoc.exists) return console.log(`User doc not found for faculty ID: ${facultyId}`);

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    // **FIXED**: Added detailed information to the notification body.
    const dutyDateTime = dutyData.dutyDateTime.toDate();
    const formattedDate = new Intl.DateTimeFormat('en-US', { dateStyle: 'medium' }).format(dutyDateTime);
    const formattedTime = new Intl.DateTimeFormat('en-US', { timeStyle: 'short' }).format(dutyDateTime);

    const notificationTitle = "New Invigilation Duty Assigned!";
    const notificationBody = `Duty in Room ${dutyData.roomNo} on ${formattedDate} at ${formattedTime}.`;

    // A) Create a persistent notification record in Firestore
    await admin.firestore().collection("notifications").add({
      userId: facultyId,
      title: notificationTitle,
      body: notificationBody,
      isRead: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // B) Send the push notification
    if (fcmToken) {
      const payload = {
        notification: { title: notificationTitle, body: notificationBody },
        token: fcmToken,
      };
      await admin.messaging().send(payload);
      console.log("Duty notification sent successfully!");
    }
  } catch (error) {
    console.error("Error sending duty notification:", error);
  }
});

// ... (Your other functions: notifyAdminsOnStatusChange and deleteUserAccount)


//---------------------- Old Code (23.08.25) ----------------------------------------


//const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
//const {onCall} = require("firebase-functions/v2/https");
//const admin = require("firebase-admin");
//
//admin.initializeApp();
//
//// Function 1: Triggers when a new duty is created.
//exports.sendDutyNotification = onDocumentCreated("duties/{dutyId}", async (event) => {
//  const dutyData = event.data.data();
//  const facultyId = dutyData.facultyId;
//
//  if (!facultyId) {
//    return console.log("No faculty ID found.");
//  }
//
//  try {
//    const userDoc = await admin.firestore().collection("users").doc(facultyId).get();
//    if (!userDoc.exists) return console.log(`User doc not found for faculty ID: ${facultyId}`);
//
//    const userData = userDoc.data();
//    const fcmToken = userData.fcmToken;
//    const notificationTitle = "New Invigilation Duty Assigned!";
//    const notificationBody = `You have been assigned duty in Room ${dutyData.roomNo}.`;
//
//    await admin.firestore().collection("notifications").add({
//      userId: facultyId,
//      title: notificationTitle,
//      body: notificationBody,
//      isRead: false,
//      timestamp: admin.firestore.FieldValue.serverTimestamp(),
//    });
//
//    if (fcmToken) {
//      const payload = {
//        notification: { title: notificationTitle, body: notificationBody },
//        token: fcmToken,
//      };
//      await admin.messaging().send(payload);
//      console.log("Duty notification sent successfully!");
//    }
//  } catch (error) {
//    console.error("Error sending duty notification:", error);
//  }
//});
//
//// Function 2: Triggers when a faculty's status is updated.
//exports.notifyAdminsOnStatusChange = onDocumentUpdated("facultyStatus/{facultyId}", async (event) => {
//  const statusData = event.data.after.data();
//  const facultyName = statusData.facultyName || "A faculty member";
//  const newStatus = statusData.status;
//
//  const notificationTitle = "Faculty Status Updated";
//  const notificationBody = `${facultyName} is now ${newStatus}.`;
//
//  try {
//    const adminsSnapshot = await admin.firestore().collection("users").where("role", "==", "admin").get();
//    if (adminsSnapshot.empty) {
//      return console.log("No admin users found to notify.");
//    }
//
//    const batch = admin.firestore().batch();
//    adminsSnapshot.forEach((adminDoc) => {
//      const adminId = adminDoc.id;
//      const notificationsRef = admin.firestore().collection("notifications").doc();
//      batch.set(notificationsRef, {
//        userId: adminId,
//        title: notificationTitle,
//        body: notificationBody,
//        isRead: false,
//        timestamp: admin.firestore.FieldValue.serverTimestamp(),
//      });
//    });
//    await batch.commit();
//    console.log(`Status change notifications created for ${adminsSnapshot.size} admins.`);
//
//  } catch (error) {
//    console.error("Error notifying admins of status change:", error);
//  }
//});
//
//
//// Function 3: Securely deletes a user's account and all associated data.
//exports.deleteUserAccount = onCall(async (request) => {
//  // Check if the user is authenticated.
//  if (!request.auth) {
//    throw new functions.https.HttpsError(
//      "unauthenticated",
//      "You must be logged in to delete an account."
//    );
//  }
//
//  const uid = request.auth.uid;
//
//  try {
//    // 1. Delete the user from Firebase Authentication
//    await admin.auth().deleteUser(uid);
//    console.log(`Successfully deleted auth user: ${uid}`);
//
//    // 2. Delete the user's document from Firestore
//    await admin.firestore().collection("users").doc(uid).delete();
//    console.log(`Successfully deleted firestore user: ${uid}`);
//
//    // 3. Delete the user's profile picture from Storage (optional, but good practice)
//    const bucket = admin.storage().bucket();
//    const filePath = `profile_pictures/${uid}`;
//    const file = bucket.file(filePath);
//    const [exists] = await file.exists();
//    if (exists) {
//      await file.delete();
//      console.log(`Successfully deleted storage file: ${filePath}`);
//    }
//
//    return { success: true, message: "Account deleted successfully." };
//  } catch (error) {
//    console.error(`Error deleting user ${uid}:`, error);
//    throw new functions.https.HttpsError(
//      "internal",
//      "An error occurred while deleting the account."
//    );
//  }
//});
