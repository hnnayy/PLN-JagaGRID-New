const express = require('express');
const admin = require('firebase-admin');
const cron = require('node-cron');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(express.json());

// ── Init Firebase ──
let db;
try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || process.env.FIREBASE_KEY);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  db = admin.firestore();
  console.log('✅ Firebase connected');
} catch (e) {
  console.error('❌ Firebase init error:', e.message);
}

const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN || process.env.TELEGRAM_TOKEN;

console.log('🔥 STARTING APP...');
console.log('TOKEN ADA:', TELEGRAM_TOKEN ? 'YA' : 'TIDAK');

function toTitleCase(str) {
  return (str || '').replace(/\w\S*/g, (w) =>
    w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()
  );
}

function normalizeUnit(str) {
  return (str || '')
    .trim()
    .toLowerCase()
    .replace(/^(ulp|up3)\s+/, '');
}

// ✅ FIX: Hapus parse_mode Markdown, kirim plain text langsung
async function sendTelegram(chatId, message, replyMarkup = null) {
  const parsedId = parseInt(chatId);
  console.log(`📤 Kirim ke chat_id: ${parsedId} (type: ${typeof parsedId})`);

  try {
    const body = {
      chat_id: parsedId,
      text: message,
      // ✅ Tidak pakai Markdown sama sekali → tidak akan error
    };
    if (replyMarkup) body.reply_markup = replyMarkup;

    await axios.post(
      `https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`,
      body
    );
    console.log(`✅ Telegram terkirim ke ${chatId}`);
  } catch (e) {
    console.error(`❌ Gagal kirim Telegram ke ${chatId}:`, e.message);
    if (e.response?.data) {
      console.error(`❌ Detail error:`, JSON.stringify(e.response.data));
    }
  }
}

async function getChatIds(up3, ulp) {
  const snapshot = await db
    .collection('users')
    .where('status', '==', 1)
    .get();

  const chatIds = [];

  snapshot.forEach((doc) => {
    const data = doc.data();
    const chatId = (data.chat_id_telegram || '').toString().trim();
    if (!chatId || !/^-?\d{8,20}$/.test(chatId)) return;

    const level = parseInt(data.level ?? 2);
    const unit = normalizeUnit(data.unit);
    const normalizedUp3 = normalizeUnit(up3);
    const normalizedUlp = normalizeUnit(ulp);

    if (level === 1) {
      chatIds.push(chatId);
    } else if (level === 2) {
      if (unit === normalizedUp3 || unit === normalizedUlp) {
        chatIds.push(chatId);
      }
    }
  });

  return [...new Set(chatIds)];
}

function buildReplyMarkup(koordinat) {
  if (!koordinat) return null;
  const parts = koordinat.split(',');
  if (parts.length !== 2) return null;
  return {
    inline_keyboard: [[
      {
        text: '🗺 Lihat Lokasi',
        url: `https://maps.google.com/?q=${parts[0].trim()},${parts[1].trim()}`,
      },
    ]],
  };
}

app.post('/send-telegram', async (req, res) => {
  try {
    const { message, up3, ulp, koordinat } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'message wajib diisi' });
    }

    if (!db) {
      return res.status(500).json({ error: 'Firestore tidak tersedia' });
    }

    console.log(`📨 /send-telegram: up3="${up3}" ulp="${ulp}"`);

    const chatIds = await getChatIds(up3 || '', ulp || '');

    if (chatIds.length === 0) {
      console.log('⚠️ Tidak ada penerima Telegram');
      return res.json({ status: 'ok', sent: 0, message: 'Tidak ada penerima' });
    }

    const replyMarkup = buildReplyMarkup(koordinat);

    for (const chatId of chatIds) {
      await sendTelegram(chatId, message, replyMarkup);
    }

    console.log(`✅ /send-telegram selesai — terkirim ke ${chatIds.length} user`);
    res.json({ status: 'ok', sent: chatIds.length });
  } catch (e) {
    console.error('❌ Error /send-telegram:', e.message);
    res.status(500).json({ error: e.message });
  }
});

async function sendH3Reminders() {
  if (!db) {
    console.error('❌ Firestore tidak tersedia');
    return;
  }

  console.log('🔔 Mulai cek H-3 reminders...');

  try {
    const now = new Date();
    const targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + 3);

    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    console.log(`📅 Cek prediksi untuk tanggal: ${startOfDay.toLocaleDateString('id-ID')}`);

    const snapshot = await db
      .collection('growth_predictions')
      .where('status', '==', 1)
      .where('predicted_next_execution', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
      .where('predicted_next_execution', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
      .get();

    if (snapshot.empty) {
      console.log('✅ Tidak ada H-3 hari ini');
      return;
    }

    console.log(`📋 Ditemukan ${snapshot.size} prediksi H-3`);

    for (const doc of snapshot.docs) {
      const prediction = doc.data();
      const predictionId = doc.id;

      const logRef = db.collection('reminder_logs').doc(predictionId);
      const logDoc = await logRef.get();
      if (logDoc.exists) {
        console.log(`⏭️ Skip ${predictionId} — sudah pernah dikirim`);
        continue;
      }

      const dataPohonId = prediction.data_pohon_id;
      const pohonDoc = await db.collection('data_pohon').doc(dataPohonId).get();
      if (!pohonDoc.exists) {
        console.log(`⚠️ Data pohon tidak ditemukan: ${dataPohonId}`);
        continue;
      }

      const pohon = pohonDoc.data();
      const up3 = pohon.up3 || '';
      const ulp = pohon.ulp || '';
      const namaPohon = pohon.nama_pohon || '-';
      const idPohon = pohon.id_pohon || '-';
      const penyulang = pohon.penyulang || '-';
      const koordinat = pohon.koordinat || '';
      const ulpFormatted = toTitleCase(ulp);

      const jadwalDate = prediction.predicted_next_execution.toDate();
      const jadwalStr = jadwalDate.toLocaleDateString('id-ID', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      });

      // ✅ FIX: Hapus * dan _ → tidak ada Markdown → tidak akan error
      const telegramMsg =
`⚠️ Pengingat Eksekusi H-3
--------------------
Pohon      : ${namaPohon}
ID         : ${idPohon}
ULP        : ${ulpFormatted || '-'}
Penyulang  : ${penyulang}
Jadwal     : ${jadwalStr}
--------------------
Segera lakukan persiapan eksekusi.
PLN JagaGRID`;

      const appTitle = `Pengingat H-3 — ${namaPohon}`;
      const appMessage = `${idPohon} • ${ulpFormatted} • Jadwal: ${jadwalStr}`;

      const replyMarkup = buildReplyMarkup(koordinat);

      const chatIds = await getChatIds(up3, ulp);
      console.log(`📋 Penerima untuk pohon ${idPohon}: ${chatIds.join(', ')}`);

      if (chatIds.length === 0) {
        console.log(`⚠️ Tidak ada penerima untuk pohon ${idPohon}`);
      }

      for (const chatId of chatIds) {
        await sendTelegram(chatId, telegramMsg, replyMarkup);
      }

      await db.collection('notification').add({
        title: appTitle,
        message: appMessage,
        date: new Date().toISOString(),
        id_pohon: idPohon,
        id_data_pohon: dataPohonId,
        up3,
        ulp,
        created_by: 'system',
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      await logRef.set({
        prediction_id: predictionId,
        data_pohon_id: dataPohonId,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
        recipients: chatIds.length,
      });

      console.log(`✅ H-3 terkirim untuk pohon ${idPohon} ke ${chatIds.length} penerima`);
    }

    console.log('✅ Selesai proses H-3 reminders');
  } catch (e) {
    console.error('❌ Error saat proses H-3:', e);
  }
}

cron.schedule('0 8 * * *', () => {
  console.log('⏰ Cron H-3 triggered:', new Date().toISOString());
  sendH3Reminders();
}, {
  timezone: 'Asia/Makassar',
});

app.get('/trigger-h3', async (req, res) => {
  console.log('🔧 Manual trigger H-3...');
  res.json({ status: 'ok', message: 'H-3 check dimulai, cek logs Railway' });
  sendH3Reminders().catch(console.error);
});

app.get('/webhook', (req, res) => {
  res.send('Webhook aktif ✅');
});

app.post('/webhook', async (req, res) => {
  try {
    const message = req.body.message;
    if (!message) return res.send('ok');

    const chatId = message.chat.id;
    const username = message.from.username || '';
    const text = message.text;

    console.log('📩 Message:', text, 'dari:', username);

    if (db && username) {
      await db.collection('telegram_users').doc(username).set({
        username_telegram: username,
        chat_id: chatId,
        last_message: text,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log('✅ Tersimpan:', username, chatId);
    }

    await axios.post(
      `https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`,
      {
        chat_id: chatId,
        text: '✅ Kamu sudah terhubung ke PLN JagaGRID!',
      }
    );

    res.send('ok');
  } catch (err) {
    console.error('❌ Error webhook:', err);
    res.status(500).send('error');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('🚀 Server jalan di port', PORT);
  console.log('⏰ Cron H-3 aktif — tiap hari 08.00 WITA');
});