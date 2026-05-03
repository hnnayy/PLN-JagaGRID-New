const express = require("express");
const fetch = require("node-fetch");
// const admin = require("firebase-admin"); ❌ dimatiin dulu

const app = express();
app.use(express.json());

// 🔐 Ambil dari Railway Variables
const TELEGRAM_TOKEN = process.env.TELEGRAM_TOKEN;

console.log("🔥 STARTING APP...");
console.log("TOKEN ADA:", TELEGRAM_TOKEN ? "YA" : "TIDAK");

// ❌ MATIKAN SEMUA FIREBASE DULU
/*
let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
} catch (e) {
  console.error("❌ FIREBASE_KEY ERROR:", e.message);
}

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  console.error("❌ Firebase tidak diinisialisasi");
}

const db = admin.firestore();
*/

// ✅ TEST ENDPOINT
app.get("/webhook", (req, res) => {
  res.send("Webhook aktif ✅");
});

// ✅ WEBHOOK TELEGRAM
app.post("/webhook", async (req, res) => {
  try {
    const message = req.body.message;

    if (!message) return res.send("ok");

    const chatId = message.chat.id;
    const username = message.from.username || "";
    const text = message.text;

    console.log("📩 Message:", text);

    // ❌ SIMPAN FIRESTORE DIMATIKAN DULU

    // ✅ BALAS KE TELEGRAM
    if (!TELEGRAM_TOKEN) {
      console.error("❌ TOKEN KOSONG");
      return res.send("token error");
    }

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
    console.error("❌ Error:", err);
    res.status(500).send("error");
  }
});

// ✅ WAJIB untuk Railway
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("🚀 Server jalan di port", PORT);
});