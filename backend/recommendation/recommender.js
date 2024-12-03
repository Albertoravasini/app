const admin = require('firebase-admin');

class VideoRecommender {
  constructor() {
    this.baseWeights = {
      WATCH_TIME: 0.35,
      ENGAGEMENT: 0.25,
      USER_INTEREST: 0.20,
      COMPLETION_RATE: 0.15,
      RECENCY: 0.05,
    };
    // Cache per le statistiche dei video
    this.statsCache = new Map();
  }

  async getRecommendedVideos(userId, limit = 10, selectedTopic = null) {
    try {
      // 1. Ottieni dati utente
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log('Utente non trovato');
        return [];
      }

      const userData = userDoc.data();
      
      // 2. Analizza la cronologia dell'utente per calcolare gli interessi
      const userInterests = await this._analyzeUserInterests(userData);
      
      // 3. Ottieni i video in base al topic selezionato
      const videosQuery = admin.firestore().collection('levels');
      
      if (selectedTopic && selectedTopic !== 'Just Learn') {
        console.log(`Filtrando per topic specifico: ${selectedTopic}`);
        const filteredVideos = await videosQuery
          .where('topic', '==', selectedTopic)
          .get();
        return this._processVideos(filteredVideos, userData, limit);
      }

      // 4. Se siamo in "Just Learn", usa l'algoritmo di raccomandazione completo
      console.log('Modalità Just Learn: applicando algoritmo di raccomandazione completo');
      const allVideos = await videosQuery.get();
      return this._processVideosWithRecommendation(allVideos, userData, userInterests, limit);
    } catch (error) {
      console.error('Errore in getRecommendedVideos:', error);
      return [];
    }
  }

  async _processVideosWithRecommendation(videosSnapshot, userData, userInterests, limit) {
    try {
      const processId = Math.random().toString(36).substring(7); // ID unico per questo processo
      console.time(`processVideos_${processId}`);
      
      // Log iniziale
      console.log(`Inizio elaborazione video per processo ${processId}`);
      console.time(`preloadStats_${processId}`);

      const watchedVideos = this._getWatchedVideoIds(userData);
      console.log(`Video già visti trovati: ${watchedVideos.size}`);

      const processedVideos = new Set();
      const validVideos = [];

      // Precarica statistiche
      const videoIds = new Set();
      videosSnapshot.docs.forEach(doc => {
        const level = doc.data();
        (level.steps || []).forEach(step => {
          if (step.type === 'video' && step.isShort && step.content) {
            videoIds.add(step.content);
          }
        });
      });

      // Carica statistiche
      await this._preloadVideoStats(Array.from(videoIds));
      console.timeEnd(`preloadStats_${processId}`);

      console.time(`scoring_${processId}`);
      // Processa i video
      for (const doc of videosSnapshot.docs) {
        const level = doc.data();
        const videoSteps = (level.steps || []).filter(step => {
          const isWatched = watchedVideos.has(step.content);
          if (isWatched) {
            console.log(`Filtro video già visto: ${step.content}`);
          }
          return (
            step.type === 'video' && 
            step.isShort === true && 
            step.content && 
            !watchedVideos.has(step.content) && // Filtra i video già visti
            !processedVideos.has(step.content)
          );
        });

        for (const step of videoSteps) {
          const videoId = step.content;
          processedVideos.add(videoId);

          try {
            const score = await this._calculateRecommendationScore(
              step,
              level,
              userData,
              userInterests
            );

            validVideos.push({
              videoId,
              score,
              level,
              step
            });
          } catch (error) {
            console.error(`Errore per video ${videoId}:`, error);
          }
        }
      }
      console.timeEnd(`scoring_${processId}`);

      // Ordina e limita
      console.time(`sorting_${processId}`);
      const result = validVideos
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      console.timeEnd(`sorting_${processId}`);

      // Log finale
      console.timeEnd(`processVideos_${processId}`);
      console.log(`Processo ${processId} completato:`, {
        totalVideos: videoIds.size,
        processedVideos: processedVideos.size,
        validVideos: validVideos.length,
        returnedVideos: result.length
      });

      return result;

    } catch (error) {
      console.error('Errore in processVideos:', error);
      return [];
    }
  }

  async _preloadVideoStats(videoIds) {
    try {
      const batchSize = 30;
      const batches = [];
      let totalLoaded = 0;
      
      // Dividi in batch
      for (let i = 0; i < videoIds.length; i += batchSize) {
        batches.push(videoIds.slice(i, i + batchSize));
      }

      console.log(`Caricamento statistiche in ${batches.length} batch...`);

      // Esegui le query per ogni batch
      const promises = batches.map(async (batch, index) => {
        try {
          const querySnapshot = await admin.firestore()
            .collection('videoStats')
            .where(admin.firestore.FieldPath.documentId(), 'in', batch)
            .get();

          querySnapshot.docs.forEach(doc => {
            this.statsCache.set(doc.id, doc.data());
            totalLoaded++;
          });

          console.log(`Batch ${index + 1}/${batches.length} completato`);
        } catch (error) {
          console.error(`Errore nel batch ${index + 1}:`, error);
        }
      });

      await Promise.all(promises);
      console.log(`Statistiche caricate: ${totalLoaded}/${videoIds.length} video`);
    } catch (error) {
      console.error('Errore nel precaricamento stats:', error);
    }
  }

  // Usa la cache per le statistiche
  async _getVideoStats(videoId) {
    if (!videoId) return null;
    return this.statsCache.get(videoId) || null;
  }

  // Ottimizza il calcolo dei punteggi
  async _calculateRecommendationScore(step, level, userData, userInterests) {
    if (!step.content) return 0;

    const videoId = step.content;
    const stats = await this._getVideoStats(videoId);

    // Calcola tutti i punteggi in una volta
    const scores = {
      watchTime: stats ? Math.min((stats.averageWatchTime || 0) / (stats.duration || 60), 1) : 0,
      engagement: stats ? Math.min(((stats.buttonClicks || 0) + (stats.commentCount || 0) * 2) / (stats.viewCount || 1), 1) : 0,
      userInterest: userInterests.get(level.topic) || 0.1,
      completion: stats ? Math.min((stats.completions || 0) / (stats.viewCount || 1), 1) : 0,
      recency: step.createdAt ? Math.max(0, 1 - ((Date.now() - step.createdAt.toDate().getTime()) / (30 * 24 * 60 * 60 * 1000))) : 0.5
    };

    // Calcola il punteggio finale
    return Object.entries(this.baseWeights).reduce((score, [key, weight]) => {
      return score + (scores[key.toLowerCase()] * weight);
    }, 0);
  }

  async _analyzeUserInterests(userData) {
    const interests = new Map();
    let totalWatched = 0;

    // Analizza la cronologia dei video guardati
    Object.entries(userData.WatchedVideos || {}).forEach(([topic, videos]) => {
      const topicVideos = videos.length;
      interests.set(topic, topicVideos);
      totalWatched += topicVideos;
    });

    // Normalizza gli interessi
    if (totalWatched > 0) {
      interests.forEach((count, topic) => {
        interests.set(topic, count / totalWatched);
      });
    }

    return interests;
  }

  _applyDiversityBoost(sortedVideos) {
    const diversified = [];
    const usedTopics = new Set();
    const remainingVideos = [...sortedVideos];

    // Prima passa: seleziona i migliori video da topic diversi
    while (remainingVideos.length > 0 && usedTopics.size < 3) {
      const index = remainingVideos.findIndex(video => 
        !usedTopics.has(video.level.topic)
      );

      if (index === -1) break;

      const video = remainingVideos.splice(index, 1)[0];
      usedTopics.add(video.level.topic);
      diversified.push(video);
    }

    // Aggiungi i video rimanenti
    return [...diversified, ...remainingVideos];
  }

  // Helper methods...
  _getWatchedVideoIds(userData) {
    console.log("Controllo video visti dall'utente:", userData.WatchedVideos);
    const watchedIds = new Set();

    if (!userData.WatchedVideos) {
      console.log("Nessun video visto trovato per l'utente");
      return watchedIds;
    }

    // Itera su tutti i topic
    Object.values(userData.WatchedVideos || {}).forEach(videos => {
      videos.forEach(video => {
        if (video.videoId) {
          watchedIds.add(video.videoId);
          console.log(`Video aggiunto alla lista dei visti: ${video.videoId}`);
        }
      });
    });

    console.log(`Totale video visti: ${watchedIds.size}`);
    console.log("Lista video visti:", Array.from(watchedIds));

    return watchedIds;
  }
}

module.exports = VideoRecommender;
