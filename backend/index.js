const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const admin = require('firebase-admin');
const compression = require('compression');
const cors = require('cors');
require('dotenv').config();
const path = require('path');

// Prima importa tutti i router
const generateQuestionsRouter = require('./questions/generate_questions');
const aiSummaryRouter = require('./ai_summary');
const aiChatRouter = require('./ai_chat');
const shortsRouter = require('./shorts');
const articlesRouter = require('./articles');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(compression());

// Poi definisci le route
app.use('/ai', aiSummaryRouter);
app.use('/ai', aiChatRouter);
app.use('/', shortsRouter);
app.use('/', generateQuestionsRouter);
app.use('/', articlesRouter);

// Aggiungi gestione errori 404
app.use((req, res) => {
  console.log(`404 - Route non trovata: ${req.method} ${req.url}`);
  res.status(404).json({
    success: false,
    message: 'Endpoint non trovato'
  });
});

// INFINE avvia il server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});

// Inizializza Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, process.env.GOOGLE_APPLICATION_CREDENTIALS));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://app-just-learn.firebaseio.com"
});

const redisClient = redis.createClient();
redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

(async () => {
  await redisClient.connect();
})();

// Funzione per inviare notifiche push
async function sendPushNotification(token, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message: ${response}`);
  } catch (error) {
    console.error(`Error sending message to token ${token}:`, error);
  }
}

// Funzione per calcolare il prossimo ritardo di notifica utilizzando backoff esponenziale
function getNextNotificationDelay(lastNotificationDelay) {
  if (lastNotificationDelay == null) {
    return 6 * 60 * 60 * 1000; // 6 ore in millisecondi
  } else if (lastNotificationDelay < 24 * 60 * 60 * 1000) {
    return lastNotificationDelay * 2; // Raddoppia l'intervallo
  } else {
    return 24 * 60 * 60 * 1000; // Massimo 24 ore in millisecondi
  }
}

// Programma una notifica con un ritardo specificato, evitando ore notturne
function scheduleNotification(token, title, body, delay) {
  let sendTime = Date.now() + delay;
  let sendDate = new Date(sendTime);
  let hours = sendDate.getHours();

  // Se l'ora è tra le 22 e le 8 del mattino, posticipa la notifica alle 8 del mattino successivo
  if (hours >= 22 || hours < 8) {
    let nextMorning = new Date(sendDate);
    if (hours >= 22) {
      // Aggiungi un giorno se sono dopo le 22
      nextMorning.setDate(nextMorning.getDate() + 1);
    }
    nextMorning.setHours(8, 0, 0, 0);
    delay = nextMorning.getTime() - Date.now();
  }

  console.log(`Scheduling notification: "${title}" to be sent after ${delay / 1000} seconds`);

  setTimeout(() => {
    console.log(`Sending notification: "${title}" now`);
    sendPushNotification(token, title, body);
  }, delay);
}

// Funzione per programmare la notifica con la nuova logica
async function schedulePushNotification(uid, token) {
  console.log(`Scheduling notifications for user ${uid} with token ${token}`);
  const lastAccess = await redisClient.get(`user_last_access_${uid}`);

  if (!lastAccess) {
    console.log(`No last access time found for user ${uid}`);
    return;
  }

  console.log(`Last access for user ${uid}: ${lastAccess}`);

  // Ottieni l'ultimo ritardo di notifica
  let lastNotificationDelay = await redisClient.get(`user_last_notification_delay_${uid}`);
  lastNotificationDelay = lastNotificationDelay ? parseInt(lastNotificationDelay) : null;

  // Calcola il prossimo ritardo di notifica
  const nextNotificationDelay = getNextNotificationDelay(lastNotificationDelay);

  // Salva il prossimo ritardo di notifica
  await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay);

  // Recupera informazioni sull'utente per personalizzare la notifica
  let userName = 'Amico';
  try {
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      userName = userData.name || 'Amico';
    }
  } catch (error) {
    console.error(`Error fetching user data for uid ${uid}:`, error);
  }

  // Personalizza il messaggio della notifica
  const notificationTitle = `⏰ Time’s Ticking!`;
  const notificationBody = `Don’t let another minute go to waste. Enhance your skills now! 💡📱`;

  // Programma la notifica
  scheduleNotification(
    token,
    notificationTitle,
    notificationBody,
    nextNotificationDelay
  );
}