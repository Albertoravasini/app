const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const { fetchVideosFromYouTube } = require('./videos/fetchVideos');
const { extractVideoText } = require('./videos/extractVideoText');
const { generateQuestionAndAnswer } = require('./questions/generateQuestions');

const app = express();
const port = process.env.PORT || 3000;

app.use(bodyParser.json());

const redisClient = redis.createClient();
redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

(async () => {
  await redisClient.connect();
})();

app.post('/new_videos', async (req, res) => {
  const { keywords, viewedVideos, pageToken, topic } = req.body;
  const actualPageToken = pageToken || '';
  try {
    const allVideos = [];
    let nextPageToken = null;

    for (const keyword of keywords) {
      const cacheKey = `videos_${keyword}_${actualPageToken}`;
      const cachedData = await redisClient.get(cacheKey);
      if (cachedData) {
        const data = JSON.parse(cachedData);
        let newVideos = data.videoDetails.filter(video => !viewedVideos.includes(video.id));
        if (newVideos.length === 0) {
          const { videoDetails, nextPageToken: newPageToken } = await fetchVideosFromYouTube([keyword], actualPageToken, topic);
          await redisClient.setEx(cacheKey, 86400, JSON.stringify({ videoDetails, nextPageToken: newPageToken }));
          newVideos = videoDetails.filter(video => !viewedVideos.includes(video.id));
          nextPageToken = newPageToken;
        } else {
          nextPageToken = data.nextPageToken;
        }
        allVideos.push(...newVideos);
      } else {
        const { videoDetails, nextPageToken: newPageToken } = await fetchVideosFromYouTube([keyword], actualPageToken, topic);
        await redisClient.setEx(cacheKey, 86400, JSON.stringify({ videoDetails, nextPageToken: newPageToken }));
        const newVideos = videoDetails.filter(video => !viewedVideos.includes(video.id));
        allVideos.push(...newVideos);
        nextPageToken = newPageToken;
      }
    }

    // Shuffle the videos to ensure a mix of different keywords
    allVideos.sort(() => Math.random() - 0.5);

    res.json({ videos: allVideos, nextPageToken });
  } catch (error) {
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

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});