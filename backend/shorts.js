// backend/shorts.js
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const VideoRecommender = require('./recommendation/recommender');

// Endpoint to get processed short steps
router.post('/get_short_steps', async (req, res) => {
  try {
    const { selectedTopic, selectedSubtopic, uid, showSavedVideos } = req.body;
    console.log('1. Richiesta ricevuta:', { 
      uid, 
      selectedTopic,
      selectedSubtopic 
    });

    const recommender = new VideoRecommender();
    const recommendedVideos = await recommender.getRecommendedVideos(
      uid, 
      20, 
      selectedTopic  // Passiamo il topic selezionato
    );
    
    console.log('2. Video raccomandati ricevuti:', {
      count: recommendedVideos.length,
      topic: selectedTopic || 'tutti i topic'
    });

    if (!recommendedVideos || recommendedVideos.length === 0) {
      console.log('3. Nessun video disponibile');
      return res.json({ success: true, data: [] });
    }

    // Ottieni i dati dell'utente per verificare i video salvati
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();

    const userData = userDoc.exists ? userDoc.data() : {};
    const savedVideos = new Set((userData.SavedVideos || []).map(v => v.videoId));

    const allShortSteps = recommendedVideos.map(video => ({
      step: {
        type: 'video',
        content: video.videoId,
        videoUrl: video.videoUrl,
        isShort: true,
        title: video.title || '',
        topic: video.topic || selectedTopic,
        thumbnailUrl: video.thumbnailUrl,
        duration: video.duration
      },
      level: video.level,
      course: video.course,
      showQuestion: false,
      isSaved: savedVideos.has(video.videoId),
      isWatched: false
    }));

    console.log('4. Short steps preparati:', {
      count: allShortSteps.length,
      topic: selectedTopic || 'tutti i topic'
    });

    res.json({ success: true, data: allShortSteps });
    
  } catch (error) {
    console.error('Error fetching short steps:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Funzione per aggiornare le statistiche del video
async function updateVideoStats(userId, videoId) {
  try {
    const statsRef = admin.firestore().collection('videoStats').doc(videoId);
    const statsDoc = await statsRef.get();

    if (!statsDoc.exists) {
      // Crea nuove statistiche se non esistono
      await statsRef.set({
        viewCount: 1,
        totalWatchTime: 0,
        buttonClicks: 0,
        seekForward: 0,
        seekBackward: 0,
        completions: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      // Aggiorna le statistiche esistenti
      await statsRef.update({
        viewCount: admin.firestore.FieldValue.increment(1),
      });
    }
  } catch (error) {
    console.error('Error updating video stats:', error);
  }
}

// Endpoint per aggiornare le statistiche di engagement
router.post('/update_video_stats', async (req, res) => {
  try {
    const { videoId, userId, action, watchTime } = req.body;
    const statsRef = admin.firestore().collection('videoStats').doc(videoId);
    const statsDoc = await statsRef.get();

    if (!statsDoc.exists) {
      // Crea il documento se non esiste con tutti i campi necessari
      await statsRef.set({
        completions: 0,
        totalWatchTime: 0,
        viewCount: 0,
        buttonClicks: 0
      });
    }

    const updateData = {};

    switch (action) {
      case 'watch_time':
        // Aggiorna solo se il tempo di visualizzazione è significativo (> 1 secondo)
        if (watchTime > 1) {
          updateData.totalWatchTime = admin.firestore.FieldValue.increment(watchTime);
        }
        break;
      case 'completion':
        // Incrementa solo se il video è stato effettivamente completato
        updateData.completions = admin.firestore.FieldValue.increment(1);
        break;
      case 'view':
        // Incrementa il conteggio visualizzazioni
        updateData.viewCount = admin.firestore.FieldValue.increment(1);
        break;
      case 'button_click':
        // Incrementa il conteggio dei click sui bottoni
        updateData.buttonClicks = admin.firestore.FieldValue.increment(1);
        break;
    }

    if (Object.keys(updateData).length > 0) {
      await statsRef.update(updateData);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Error updating video stats:', error);
    res.status(500).json({ success: false, message: 'Error updating video stats' });
  }
});

module.exports = router;