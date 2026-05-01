const express = require("express");
const fetch = require("node-fetch");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());

// 🔴 ISI TOKEN BOT KAMU DI SINI
const TELEGRAM_TOKEN = "ISI_TOKEN_KAMU";

// 🔴 SETUP FIREBASE
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ✅ WEBHOOK ENDPOINT
app.post("/webhook", async (req, res) => {
  try {
    const message = req.body.message;

    if (!message) return res.send("ok");

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
        text: "✅ Kamu sudah terhubung ke PLN JagaGRID!",
      }),
    });

    res.send("ok");
  } catch (err) {
    console.error(err);
    res.status(500).send("error");
  }
});

// RUN SERVER
app.listen(3000, () => {
  console.log("🚀 Server jalan di port 3000");
});