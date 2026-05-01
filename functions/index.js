const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

const TELEGRAM_TOKEN = "8680208779:AAE8HRFkVvh41i5XHPqqLVlMhJG0f9jMRKs";

exports.telegramWebhook = onRequest(async (req, res) => {
  try {
    const message = req.body.message;

    if (!message) {
      return res.send("ok");
    }

    const chatId = message.chat.id;
    const username = message.from.username || "";
    const text = message.text;

    console.log("📩 Message:", text);

    // ✅ SIMPAN KE FIRESTORE
    await db.collection("telegram_users").doc(chatId.toString()).set({
      chat_id: chatId.toString(),
      username: username,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ✅ BALAS KE USER
    await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chat_id: chatId,
        text: "✅ Kamu sudah terdaftar di PLN JagaGRID!",
      }),
    });

    res.send("ok");
  } catch (err) {
    console.error(err);
    res.status(500).send("error");
  }
});
