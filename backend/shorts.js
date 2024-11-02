// backend/shorts.js
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// Endpoint to get processed short steps
router.post('/get_short_steps', async (req, res) => {
  try {
    const { selectedTopic, selectedSubtopic, uid, showSavedVideos } = req.body;

    let levelsQuery = admin.firestore().collection('levels');
    let coursesQuery = admin.firestore().collection('courses');

    if (!showSavedVideos) {
      // Applica i filtri solo se non stai mostrando i video salvati
      if (selectedTopic && selectedTopic !== 'Just Learn') {
        levelsQuery = levelsQuery.where('topic', '==', selectedTopic);
        coursesQuery = coursesQuery.where('topic', '==', selectedTopic);
      }

      if (selectedSubtopic && selectedSubtopic !== 'tutti') {
        levelsQuery = levelsQuery.where('subtopic', '==', selectedSubtopic);
        // Se necessario, applica anche ai corsi
      }
    }

    // Fetch Levels and Courses
    const levelsSnapshot = await levelsQuery.orderBy('subtopicOrder').orderBy('levelNumber').get();
    const levels = levelsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const coursesSnapshot = await coursesQuery.get();
    const courses = coursesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Combina shortSteps
    let shortSteps = [];
    levels.forEach(level => {
      if (Array.isArray(level.steps)) {
        level.steps.forEach(step => {
          if (step.type === 'video' && step.isShort) {
            shortSteps.push({ step, level });
          }
        });
      }
    });

    courses.forEach(course => {
      if (Array.isArray(course.sections)) {
        course.sections.forEach(section => {
          if (Array.isArray(section.steps)) {
            section.steps.forEach(step => {
              if (step.type === 'video' && step.isShort) {
                shortSteps.push({ step, course });
              }
            });
          }
        });
      }
    });

    // Fetch User Data
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    let watchedVideos = [];
    let savedVideos = [];
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData.WatchedVideos) {
        if (selectedTopic === 'Just Learn') {
          Object.values(userData.WatchedVideos).forEach(topicVideos => {
            watchedVideos = watchedVideos.concat(topicVideos);
          });
        } else {
          watchedVideos = userData.WatchedVideos[selectedTopic] || [];
        }
      }
      savedVideos = userData.SavedVideos || [];
    }

    const watchedVideoIds = new Set(watchedVideos.map(video => video.videoId));
    const savedVideoIds = new Set(savedVideos.map(video => video.videoId));

    // Filtra i video
    if (showSavedVideos) {
      console.log(`Filtraggio video salvati per l'utente ${uid}. SavedVideoIds:`, savedVideoIds);
      shortSteps = shortSteps.filter(item => {
        console.log(`Controllando step content: ${item.step.content}`);
        return savedVideoIds.has(item.step.content); // Assicurati che item.step.content sia l'ID del video
      });
    } else {
      // Nuova logica per mescolare i video
      let unWatchedSteps = shortSteps.filter(item => !watchedVideoIds.has(item.step.content));
      let watchedSteps = shortSteps.filter(item => watchedVideoIds.has(item.step.content));

      if (unWatchedSteps.length > 0) {
        // Mescola i video non visti
        unWatchedSteps.sort(() => Math.random() - 0.5);
        shortSteps = [...unWatchedSteps, ...watchedSteps];
      } else {
        // Tutti i video sono stati visti, quindi mescola tutti i video
        watchedSteps.sort(() => Math.random() - 0.5);
        shortSteps = watchedSteps;
      }
    }

    // Combine e mappa i passi
    const allShortSteps = shortSteps.map(item => ({
      step: item.step,
      level: item.level || null,
      course: item.course || null,
      showQuestion: false,
      isSaved: savedVideoIds.has(item.step.content),
      isWatched: watchedVideoIds.has(item.step.content),
    }));

    res.json({ success: true, data: allShortSteps });
  } catch (error) {
    console.error('Error fetching short steps:', error);
    res.status(500).json({ success: false, message: 'Error fetching short steps' });
  }
});

module.exports = router;