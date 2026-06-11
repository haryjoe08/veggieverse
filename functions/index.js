const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onRequest(async (req, res) => {
  const {token, title, body, data} = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    res.status(200).send("Notification sent successfully");
  } catch (error) {
    console.log("Error sending message:", error);
    res.status(500).send("Error sending notification");
  }
});
