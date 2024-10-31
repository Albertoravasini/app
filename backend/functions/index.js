// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const redis = require('redis');

admin.initializeApp();

// Configura Redis (modifica con le tue credenziali)
const redisClient = redis.createClient({
  url: 'redis://:password@host:port' // Sostituisci con i tuoi dettagli
});
redisClient.connect();

exports.onNewVideo = functions.firestore
  .document('videos/{videoId}')
  .onCreate(async (snap, context) => {
    const videoData = snap.data();
    const videoId = context.params.videoId;

    // Recupera tutti gli utenti
    const usersSnapshot = await admin.firestore().collection('users').get();

    // Itera su ogni utente
    const promises = usersSnapshot.docs.map(async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const watchedVideoIds = userData.WatchedVideos ? Object.values(userData.WatchedVideos).flatMap(videos => videos.map(video => video.videoId)) : [];

      // Se l'utente ha visto tutti i video esistenti prima dell'aggiunta del nuovo video
      // In questo esempio, supponiamo che l'utente abbia visto tutti se il numero di video visti è uguale al numero di video totali meno uno (prima dell'aggiunta)
      const totalVideosSnapshot = await admin.firestore().collection('videos').get();
      const totalVideos = totalVideosSnapshot.size - 1; // Escludi il nuovo video

      if (watchedVideoIds.length >= totalVideos) {
        // Invalida la cache Redis per questo utente
        const cacheKeys = [`videos_${userId}_*`]; // Invalida tutte le cache relative ai video per questo utente

        for await (const key of cacheKeys) {
          await redisClient.del(key);
        }
      }
    });

    await Promise.all(promises);
  });