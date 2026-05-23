const express = require("express");
const fetch = require("node-fetch");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());

const TELEGRAM_TOKEN = process.env.TELEGRAM_TOKEN;

console.log("🔥 STARTING APP...");
console.log("TOKEN ADA:", TELEGRAM_TOKEN ? "YA" : "TIDAK");

// ✅ Firebase Init
let db;
try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  db = admin.firestore();
  console.log("✅ Firebase connected");
} catch (e) {
  console.error("❌ FIREBASE_KEY ERROR:", e.message);
}

// ✅ TEST ENDPOINT
app.get("/webhook", (req, res) => {
  res.send("Webhook aktif ✅");
});

// ✅ WEBHOOK TELEGRAM
app.post("/webhook", async (req, res) => {
  try {
    const message = req.body.message;
    if (!message) return res.send("ok");

    // ✅ FIX: simpan sebagai integer, bukan string
    // String(message.chat.id) menyebabkan chat_id tersimpan sebagai string
    // Telegram API butuh integer → error 400 kalau string
    const chatId = message.chat.id; // ✅ integer langsung dari Telegram
    const username = message.from.username || "";
    const text = message.text;

    console.log("📩 Message:", text, "dari:", username);

    // ✅ Simpan ke Firestore sebagai integer
    if (db && username) {
      await db.collection("telegram_users").doc(username).set({
        username_telegram: username,
        chat_id: chatId, // ✅ integer, bukan string
        last_message: text,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log("✅ Tersimpan:", username, chatId);
    }

    // ✅ Balas ke Telegram
    await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId, // ✅ integer
        text: "✅ Kamu sudah terhubung ke PLN JagaGRID!",
      }),
    });

    res.send("ok");
  } catch (err) {
    console.error("❌ Error:", err);
    res.status(500).send("error");
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("🚀 Server jalan di port", PORT);
});