const admin = require('firebase-admin');

class VideoRecommender {
  // Pesi per diverse metriche (totale 100%)
  static WEIGHTS = {
    WATCH_TIME: 0.30,        // 30% - Tempo di visualizzazione
    ENGAGEMENT: 0.25,        // 25% - Coinvolgimento (interazioni)
    TOPIC_MATCH: 0.20,       // 20% - Corrispondenza topic/subtopic
    COMPLETION_RATE: 0.15,   // 15% - Tasso di completamento
    RECENCY: 0.10,          // 10% - Data di pubblicazione
  };

  // Calcola il punteggio per ogni video
  async calculateVideoScore(video, userData) {
    try {
      if (!userData) {
        console.log('userData non definito, uso punteggio di default');
        return 1; // Punteggio di default se non ci sono dati utente
      }

      const scores = {
        watchTimeScore: await this._calculateWatchTimeScore(video.videoId) || 0,
        engagementScore: await this._calculateEngagementScore(video.videoId) || 0,
        topicMatchScore: this._calculateTopicMatchScore(video, userData) || 0,
        completionScore: await this._calculateCompletionScore(video.videoId) || 0,
        recencyScore: this._calculateRecencyScore(video.createdAt) || 0
      };

      // Calcolo punteggio finale pesato
      const finalScore = 
        (scores.watchTimeScore * VideoRecommender.WEIGHTS.WATCH_TIME) +
        (scores.engagementScore * VideoRecommender.WEIGHTS.ENGAGEMENT) +
        (scores.topicMatchScore * VideoRecommender.WEIGHTS.TOPIC_MATCH) +
        (scores.completionScore * VideoRecommender.WEIGHTS.COMPLETION_RATE) +
        (scores.recencyScore * VideoRecommender.WEIGHTS.RECENCY);

      return finalScore || 1; // Ritorna almeno 1 se il punteggio è 0
    } catch (error) {
      console.error('Errore nel calcolo del punteggio:', error);
      return 1; // Punteggio di default in caso di errore
    }
  }

  // Calcola il punteggio basato sul tempo medio di visualizzazione
  async _calculateWatchTimeScore(videoId) {
    try {
      const watchTimeStats = await admin.firestore()
        .collection('videoStats')
        .doc(videoId)
        .get();

      if (!watchTimeStats.exists) return 0;

      const stats = watchTimeStats.data();
      const avgWatchTime = stats.totalWatchTime / stats.viewCount;
      const videoDuration = stats.duration;

      // Normalizza il punteggio (0-1) basato sulla percentuale di video guardato
      return Math.min(avgWatchTime / videoDuration, 1);
    } catch (error) {
      console.error('Errore nel calcolo del watch time:', error);
      return 0;
    }
  }

  // Calcola il punteggio di coinvolgimento
  async _calculateEngagementScore(videoId) {
    try {
      const engagementStats = await admin.firestore()
        .collection('videoStats')
        .doc(videoId)
        .get();

      if (!engagementStats.exists) return 0;

      const stats = engagementStats.data();
      
      // Calcola il punteggio basato su diverse metriche di coinvolgimento
      const buttonClicks = stats.buttonClicks || 0;
      const seekForward = stats.seekForward || 0;
      const seekBackward = stats.seekBackward || 0;
      const totalViews = stats.viewCount || 1;

      // Normalizza le interazioni per visualizzazione
      const interactionsPerView = (buttonClicks + seekForward + seekBackward) / totalViews;
      
      // Limita il punteggio a 1
      return Math.min(interactionsPerView / 10, 1);
    } catch (error) {
      console.error('Errore nel calcolo dell\'engagement:', error);
      return 0;
    }
  }

  // Calcola la corrispondenza del topic
  _calculateTopicMatchScore(video, userData) {
    try {
      const userTopics = new Set(userData.topics);
      const userSubtopics = new Set(userData.subtopics || []);

      // Punteggio più alto se corrisponde sia il topic che il subtopic
      if (userTopics.has(video.topic) && userSubtopics.has(video.subtopic)) {
        return 1.0;
      }
      // Punteggio medio se corrisponde solo il topic
      else if (userTopics.has(video.topic)) {
        return 0.6;
      }
      // Punteggio base per altri video
      return 0.2;
    } catch (error) {
      console.error('Errore nel calcolo del topic match:', error);
      return 0;
    }
  }

  // Calcola il tasso di completamento
  async _calculateCompletionScore(videoId) {
    try {
      // Verifica che videoId sia valido
      if (!videoId) {
        console.log('VideoId non valido:', videoId);
        return 0;
      }

      const stats = await admin.firestore()
        .collection('videoStats')
        .doc(videoId.toString()) // Assicurati che sia una stringa
        .get();

      if (!stats.exists) {
        return 0;
      }

      const data = stats.data();
      return data.completions / (data.viewCount || 1) || 0;
    } catch (error) {
      console.error('Errore nel calcolo del completion rate:', error);
      return 0;
    }
  }

  // Calcola il punteggio di recency
  _calculateRecencyScore(createdAt) {
    try {
      const now = new Date();
      const videoAge = now - createdAt;
      const thirtyDaysInMs = 30 * 24 * 60 * 60 * 1000;

      // Video più nuovi di 30 giorni ottengono punteggi più alti
      return Math.max(0, 1 - (videoAge / thirtyDaysInMs));
    } catch (error) {
      console.error('Errore nel calcolo del recency score:', error);
      return 0;
    }
  }

  // Metodo principale per ottenere i video raccomandati
  async getRecommendedVideos(userId, limit = 10, selectedTopic = null) {
    try {
      // 1. Ottieni dati utente
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        return [];
      }

      const userData = userDoc.data();

      // 2. Raccogli video già visti
      const watchedVideos = new Set();
      if (userData.WatchedVideos) {
        Object.entries(userData.WatchedVideos).forEach(([topic, videos]) => {
          if (Array.isArray(videos)) {
            videos.forEach(video => watchedVideos.add(video.videoId));
          }
        });
      }

      // 3. Ottieni tutti i video
      const videosSnapshot = await admin.firestore()
        .collection('levels')
        .get();

      // 4. Filtra i video
      const validVideos = videosSnapshot.docs.flatMap(doc => {
        const level = doc.data();
        
        if (selectedTopic && selectedTopic !== 'Just Learn' && level.topic !== selectedTopic) {
          return [];
        }

        return (level.steps || [])
          .filter(step => {
            const videoId = step.content || this._extractVideoId(step.videoUrl);
            const checks = {
              isVideo: step?.type === 'video',
              isShort: step?.isShort === true,
              hasUrl: !!(step?.videoUrl || step?.content),
              notWatched: !watchedVideos.has(videoId)
            };
            return Object.values(checks).every(check => check);
          })
          .map(step => ({
            ...step,
            videoId: step.content || this._extractVideoId(step.videoUrl),
            videoUrl: step.videoUrl || `https://youtube.com/watch?v=${step.content}`,
            topic: level.topic,
            subtopic: level.subtopic,
            level: {
              id: doc.id,
              title: level.title,
              topic: level.topic,
              subtopic: level.subtopic
            }
          }));
      });

      // 5. Mescola e seleziona
      const shuffledVideos = this._shuffleArray(validVideos);
      return shuffledVideos.slice(0, limit);

    } catch (error) {
      return [];
    }
  }

  // Metodo helper per estrarre videoId da videoUrl
  _extractVideoId(videoUrl) {
    if (!videoUrl) return null;
    
    // Estrai l'ID del video da un URL di YouTube
    const match = videoUrl.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/);
    return match ? match[1] : null;
  }

  // Metodo helper per mescolare un array
  _shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
  }
}

module.exports = VideoRecommender;
