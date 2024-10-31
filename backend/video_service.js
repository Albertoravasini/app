// video_service.js

const fetchVideos = async (uid, lastVideoId, limit, selectedTopic, selectedSubtopic, showSavedVideos, db, redisClient) => {
    // Build cache key
    const cacheKey = `videos_${uid}_${selectedTopic}_${selectedSubtopic}_${lastVideoId}_${showSavedVideos}`;
    const cachedVideos = await redisClient.get(cacheKey);
  
    if (cachedVideos) {
      console.log('Returning videos from cache');
      return JSON.parse(cachedVideos);
    }
  
    // Fetch user data
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.exists ? userDoc.data() : null;
  
    const watchedVideoIds = new Set();
    const savedVideoIds = new Set();
    const userTopics = new Set(userData?.topics || []);
  
    if (userData && userData.WatchedVideos) {
      for (const topic in userData.WatchedVideos) {
        userData.WatchedVideos[topic].forEach(video => watchedVideoIds.add(video.videoId));
      }
    }
  
    if (userData && userData.SavedVideos) {
      userData.SavedVideos.forEach(video => savedVideoIds.add(video.videoId));
    }
  
    // Build the query based on the selected topic and subtopic
    let query = db.collection('levels');
  
    if (selectedTopic && selectedTopic !== 'Just Learn') {
      query = query.where('topic', '==', selectedTopic);
    }
  
    if (selectedSubtopic && selectedSubtopic !== 'tutti') {
      query = query.where('subtopic', '==', selectedSubtopic);
    }
  
    // Order and paginate the results
    query = query.orderBy('subtopicOrder').orderBy('levelNumber').limit(limit || 10);
  
    // If lastVideoId is provided, start after that document for pagination
    if (lastVideoId) {
      const lastVideoDoc = await db.collection('videos').doc(lastVideoId).get();
      if (lastVideoDoc.exists) {
        query = query.startAfter(lastVideoDoc);
      }
    }
  
    const querySnapshot = await query.get();
  
    // Process the videos
    let videos = [];
    for (const doc of querySnapshot.docs) {
      const levelData = doc.data();
      const steps = levelData.steps || [];
  
      // Filter short videos
      const shortSteps = steps.filter(step => step.type === 'video' && step.isShort);
  
      for (const step of shortSteps) {
        // Fetch like count
        const videoDoc = await db.collection('videos').doc(step.content).get();
        const videoData = videoDoc.exists ? videoDoc.data() : {};
        const likeCount = videoData.likes || 0;
  
        // Determine if the video is watched or saved
        const isWatched = watchedVideoIds.has(step.content);
        const isSaved = savedVideoIds.has(step.content);
  
        // Push video with metadata
        videos.push({
          videoId: step.content,
          levelId: doc.id,
          levelTitle: levelData.title,
          topic: levelData.topic,
          subtopic: levelData.subtopic,
          likeCount: likeCount,
          isWatched: isWatched,
          isSaved: isSaved,
        });
      }
    }
  
    // Implement recommendation logic
    // Prioritize based on:
    // 1. Saved Videos
    // 2. Unwatched Videos
    // 3. Popular Videos (likeCount)
  
    // Separate saved and unsaved videos
    const savedVideosList = videos.filter(video => video.isSaved);
    const unsavedVideos = videos.filter(video => !video.isSaved);
  
    // Separate unwatched and watched videos
    const unwatchedVideos = unsavedVideos.filter(video => !video.isWatched);
    const watchedVideos = unsavedVideos.filter(video => video.isWatched);
  
    // Sort unwatched videos by likeCount descending
    unwatchedVideos.sort((a, b) => b.likeCount - a.likeCount);
  
    // Shuffle watched videos to add variety
    for (let i = watchedVideos.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [watchedVideos[i], watchedVideos[j]] = [watchedVideos[j], watchedVideos[i]];
    }
  
    // Combine the lists with priority
    const prioritizedVideos = [
      ...savedVideosList, // Highest priority
      ...unwatchedVideos, // Next priority
      ...watchedVideos    // Lowest priority
    ];
  
    // Cache the result
    await redisClient.set(cacheKey, JSON.stringify(prioritizedVideos), { EX: 120 }); // Cache for 2 minutes
  
    // Return only the limited number of videos
    return prioritizedVideos.slice(0, limit);
  };
  
  module.exports = {
    fetchVideos,
  };