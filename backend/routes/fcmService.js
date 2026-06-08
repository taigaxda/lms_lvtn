import admin from "firebase-admin";

export const sendNotification = async (tokens, title, body) => {
  const message = {
    notification: {
      title,
      body,
    },
    tokens: tokens,
  };

  try {
    const res = await admin.messaging().sendEachForMulticast(message);
    console.log("Thành công:", res.successCount);
    res.responses.forEach((r, i) => {
      if (!r.success) {
        console.log("Token lỗi:", tokens[i]);
      }
    });

  } catch (err) {
    console.error("Lỗi FCM:", err);
  }
};