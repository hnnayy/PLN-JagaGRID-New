const express = require("express");
const fetch = require("node-fetch");
const admin = require("firebase-admin");
const cron = require("node-cron");

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

// ─────────────────────────────────────────
// HELPER: Title case (ULP BARRU → ULP Barru)
// ─────────────────────────────────────────
function toTitleCase(str) {
  return (str || "").replace(/\w\S*/g, (w) =>
    w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()
  );
}

// ─────────────────────────────────────────
// HELPER: Format tanggal Indonesia
// ─────────────────────────────────────────
function formatTanggalIndo(date) {
  const bulan = [
    "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember",
  ];
  const d = new Date(date);
  return `${d.getDate()} ${bulan[d.getMonth() + 1]} ${d.getFullYear()}`;
}

// ─────────────────────────────────────────
// HELPER: Kirim Telegram ke user sesuai ULP
// ─────────────────────────────────────────
async function sendTelegramToUlp({ up3, ulp, message, koordinat }) {
  try {
    const usersSnap = await db.collection("users")
      .where("status", "==", 1)
      .get();

    const norm = (s) => (s || "").toString().trim().toLowerCase();
    const nUp3 = norm(up3);
    const nUlp = norm(ulp);

    let replyMarkup = null;
    if (koordinat) {
      const parts = koordinat.split(",");
      if (parts.length === 2) {
        const lat = parts[0].trim();
        const lng = parts[1].trim();
        replyMarkup = {
          inline_keyboard: [[
            {
              text: "🗺 Lihat Lokasi",
              url: `https://maps.google.com/?q=${lat},${lng}`,
            },
          ]],
        };
      }
    }

    for (const userDoc of usersSnap.docs) {
      const user = userDoc.data();
      const chatId = (user.chat_id_telegram || "").toString().trim();

      if (!chatId || !/^-?\d{8,20}$/.test(chatId)) continue;

      const level = parseInt(user.level || 2);
      const nUnit = norm(user.unit);

      if (level === 2 && nUnit !== nUp3 && nUnit !== nUlp) continue;

      try {
        const body = {
          chat_id: parseInt(chatId), // ✅ FIX: selalu integer ke Telegram API
          text: message,
          parse_mode: "Markdown",
        };
        if (replyMarkup) body.reply_markup = replyMarkup;

        const resp = await fetch(
          `https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
          }
        );

        if (resp.ok) {
          console.log(`✅ Telegram terkirim ke ${user.username || chatId}`);
        } else {
          const err = await resp.text();
          console.error(`❌ Gagal kirim ke ${chatId}:`, err);
        }
      } catch (e) {
        console.error(`❌ Error kirim ke ${chatId}:`, e.message);
      }
    }
  } catch (e) {
    console.error("❌ Error sendTelegramToUlp:", e.message);
  }
}

// ─────────────────────────────────────────
// HELPER: Simpan notif ke Firestore
// ─────────────────────────────────────────
async function saveNotification({ title, message, dataPohonId, up3, ulp }) {
  try {
    await db.collection("notification").add({
      title,
      message,
      id_data_pohon: dataPohonId || null,
      up3: up3 || "",
      ulp: ulp || "",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("❌ Gagal simpan notifikasi:", e.message);
  }
}

// ─────────────────────────────────────────
// CORE: Logic cek H-3
// ─────────────────────────────────────────
async function runH3Check() {
  if (!db) {
    console.error("❌ Firestore tidak tersedia");
    return;
  }

  const now = new Date();
  const nowTimestamp = admin.firestore.Timestamp.fromDate(now);
  console.log("🔍 Mulai cek H-3:", now.toISOString());

  // ─── SOURCE 1: data_pohon (jadwal awal) ───
  try {
    const pohonSnap = await db.collection("data_pohon")
      .where("status", "==", 1)
      .where("reminder_sent", "==", false)
      .where("notification_date", "<=", nowTimestamp)
      .get();

    console.log(`📋 data_pohon H-3: ${pohonSnap.size} dokumen`);

    for (const doc of pohonSnap.docs) {
      const data = doc.data();

      let scheduleStr = data.schedule_date || "-";
      try {
        if (data.schedule_date_ts) {
          scheduleStr = formatTanggalIndo(
            new Date(data.schedule_date_ts._seconds * 1000)
          );
        }
      } catch (_) {}

      const ulpFormatted = toTitleCase(data.ulp);

      const message =
`⚠️ *Pengingat Eksekusi H-3*
━━━━━━━━━━━━━━━━━━━━
Pohon      : ${data.nama_pohon || "-"}
ID         : ${data.id_pohon || "-"}
ULP        : ${ulpFormatted || "-"}
Penyulang  : ${data.penyulang || "-"}
Jadwal     : ${scheduleStr}
━━━━━━━━━━━━━━━━━━━━
Segera lakukan persiapan eksekusi.
_PLN JagaGRID_`;

      const appTitle = `Pengingat H-3 — ${data.nama_pohon || "-"}`;
      const appMessage = `${data.id_pohon || "-"} • ${ulpFormatted} • Jadwal: ${scheduleStr}`;

      await sendTelegramToUlp({
        up3: data.up3,
        ulp: data.ulp,
        message,
        koordinat: data.koordinat || null,
      });

      await saveNotification({
        title: appTitle,
        message: appMessage,
        dataPohonId: doc.id,
        up3: data.up3,
        ulp: data.ulp,
      });

      await doc.ref.update({ reminder_sent: true });
      console.log(`✅ reminder_sent=true: ${doc.id}`);
    }
  } catch (e) {
    console.error("❌ Error SOURCE 1:", e.message);
  }

  // ─── SOURCE 2: growth_predictions (repetisi Tebang Pangkas) ───
  try {
    const predSnap = await db.collection("growth_predictions")
      .where("status", "==", 1)
      .where("reminder_sent", "==", false)
      .get();

    console.log(`📋 growth_predictions: ${predSnap.size} dokumen`);

    for (const doc of predSnap.docs) {
      const pred = doc.data();

      let nextExecDate = null;
      try {
        nextExecDate = new Date(pred.predicted_next_execution._seconds * 1000);
      } catch (_) {}
      if (!nextExecDate) continue;

      const h3Date = new Date(nextExecDate);
      h3Date.setDate(h3Date.getDate() - 3);
      if (h3Date > now) continue;

      let pohonData = null;
      try {
        const pohonDoc = await db.collection("data_pohon")
          .doc(pred.data_pohon_id).get();
        if (pohonDoc.exists) pohonData = pohonDoc.data();
      } catch (_) {}
      if (!pohonData) continue;

      const scheduleStr = formatTanggalIndo(nextExecDate);
      const ulpFormatted = toTitleCase(pohonData.ulp);

      const message =
`⚠️ *Pengingat Eksekusi H-3*
━━━━━━━━━━━━━━━━━━━━
Pohon      : ${pohonData.nama_pohon || "-"}
ID         : ${pohonData.id_pohon || "-"}
ULP        : ${ulpFormatted || "-"}
Penyulang  : ${pohonData.penyulang || "-"}
Jadwal     : ${scheduleStr}
Siklus     : ${pred.repetition_cycle || "-"}
━━━━━━━━━━━━━━━━━━━━
Segera lakukan persiapan eksekusi.
_PLN JagaGRID_`;

      const appTitle = `Pengingat H-3 — ${pohonData.nama_pohon || "-"}`;
      const appMessage = `${pohonData.id_pohon || "-"} • ${ulpFormatted} • Jadwal: ${scheduleStr}`;

      await sendTelegramToUlp({
        up3: pohonData.up3,
        ulp: pohonData.ulp,
        message,
        koordinat: pohonData.koordinat || null,
      });

      await saveNotification({
        title: appTitle,
        message: appMessage,
        dataPohonId: pred.data_pohon_id,
        up3: pohonData.up3,
        ulp: pohonData.ulp,
      });

      await doc.ref.update({ reminder_sent: true });
      console.log(`✅ reminder_sent=true prediksi: ${doc.id}`);
    }
  } catch (e) {
    console.error("❌ Error SOURCE 2:", e.message);
  }

  console.log("✅ H-3 check selesai");
}

// ─────────────────────────────────────────
// CRON: Tiap hari 07.00 WITA (23.00 UTC)
// ─────────────────────────────────────────
cron.schedule("0 23 * * *", async () => {
  console.log("⏰ CRON H-3 triggered:", new Date().toISOString());
  await runH3Check();
}, { timezone: "UTC" });

// ─────────────────────────────────────────
// ENDPOINT: Manual trigger
// ─────────────────────────────────────────
app.get("/trigger-h3", async (req, res) => {
  console.log("🔧 Manual trigger H-3...");
  res.json({ status: "ok", message: "H-3 check dimulai, cek logs Railway" });
  runH3Check().catch(console.error);
});

// ─────────────────────────────────────────
// WEBHOOK TELEGRAM
// ─────────────────────────────────────────
app.get("/webhook", (req, res) => {
  res.send("Webhook aktif ✅");
});

app.post("/webhook", async (req, res) => {
  try {
    const message = req.body.message;
    if (!message) return res.send("ok");

    // ✅ FIX: simpan integer bukan string
    const chatId = message.chat.id; // ✅ integer langsung dari Telegram
    const username = message.from.username || "";
    const text = message.text;

    console.log("📩 Message:", text, "dari:", username);

    if (db && username) {
      await db.collection("telegram_users").doc(username).set({
        username_telegram: username,
        chat_id: chatId, // ✅ integer
        last_message: text,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log("✅ Tersimpan:", username, chatId);
    }

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
  console.log("⏰ Cron H-3 aktif — tiap hari 07.00 WITA");
});