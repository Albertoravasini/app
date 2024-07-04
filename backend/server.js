const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const { fetchVideosFromYouTube } = require('./videos/fetchVideos');
const { extractVideoText } = require('./videos/extractVideoText');
const { generateQuestionAndAnswer } = require('./questions/generateQuestions');
const compression = require('compression');
const admin = require('firebase-admin');

const app = express();
const port = process.env.PORT || 3000;

// Inizializza Firebase
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

app.use(bodyParser.json());
app.use(compression());

const redisClient = redis.createClient();
redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

(async () => {
  await redisClient.connect();
})();

app.post('/new_videos', async (req, res) => {
  const { keywords, viewedVideos, pageToken, topic } = req.body;
  const actualPageToken = pageToken || '';
  const cacheKey = `videos_${keywords.join('_')}_${actualPageToken}`;

  try {
    const cachedData = await redisClient.get(cacheKey);
    if (cachedData) {
      console.log(`Cache hit for keywords: ${keywords.join(', ')} with pageToken: ${actualPageToken}`);
      const data = JSON.parse(cachedData);
      let newVideos = data.videoDetails.filter(video => !viewedVideos.includes(video.id));
      const nextPageToken = data.nextPageToken || '';
      if (newVideos.length === 0) {
        console.log(`Cache miss due to no new videos, fetching from YouTube for keywords: ${keywords.join(', ')} with pageToken: ${actualPageToken}`);
        const { videoDetails, nextPageToken: newPageToken } = await fetchVideosFromYouTube(keywords, actualPageToken, topic);
        console.log(`Fetched ${videoDetails.length} videos from YouTube`);
        await redisClient.setEx(cacheKey, 86400, JSON.stringify({ videoDetails, nextPageToken: newPageToken || '' }));
        console.log(`Stored ${videoDetails.length} videos in cache for keywords: ${keywords.join(', ')} with pageToken: ${actualPageToken}`);
        newVideos = videoDetails.filter(video => !viewedVideos.includes(video.id));
        res.json({ videos: newVideos, nextPageToken: newPageToken || '' });
      } else {
        console.log(`Returning ${newVideos.length} new videos with nextPageToken: ${nextPageToken}`);
        res.json({ videos: newVideos, nextPageToken });
      }
    } else {
      console.log(`Cache miss for keywords: ${keywords.join(', ')} with pageToken: ${actualPageToken}`);
      const { videoDetails, nextPageToken: newPageToken } = await fetchVideosFromYouTube(keywords, actualPageToken, topic);
      console.log(`Fetched ${videoDetails.length} videos from YouTube`);
      await redisClient.setEx(cacheKey, 86400, JSON.stringify({ videoDetails, nextPageToken: newPageToken || '' }));
      console.log(`Stored ${videoDetails.length} videos in cache for keywords: ${keywords.join(', ')} with pageToken: ${actualPageToken}`);
      const newVideos = videoDetails.filter(video => !viewedVideos.includes(video.id));
      console.log(`Returning ${newVideos.length} new videos with nextPageToken: ${newPageToken || ''}`);
      res.json({ videos: newVideos, nextPageToken: newPageToken || '' });
    }
  } catch (error) {
    console.error('Error fetching videos:', error);
    res.status(500).send('Error fetching videos');
  }
});

app.post('/generate_question', async (req, res) => {
  const { videoUrl } = req.body;
  try {
    console.log(`Processing video URL: ${videoUrl}`);
    const videoText = await extractVideoText(videoUrl);
    console.log('Extracted video text:', videoText);
    const questionAndAnswer = await generateQuestionAndAnswer(videoText);
    res.json({ question: questionAndAnswer });
  } catch (error) {
    console.error('Error generating question:', error.message);
    res.status(500).send('Error generating question');
  }
});

// Include the admin routes
const adminRoutes = require('./admin/routes/adminRoutes');
app.use('/admin', adminRoutes);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});