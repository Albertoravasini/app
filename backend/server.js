const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const { fetchVideosFromYouTube } = require('./videos/fetchVideos');
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

  console.log(`Request received with keywords: ${keywords.join(', ')}, pageToken: ${actualPageToken}, topic: ${topic}`);

  try {
    // Step 1: Check cache for each keyword individually
    const cachedDataPromises = keywords.map(keyword => redisClient.get(`videos_${keyword}_${actualPageToken}`));
    const cachedDataResults = await Promise.all(cachedDataPromises);

    // Step 2: Collect cached videos and identify keywords with cache miss
    let cachedVideos = [];
    let keywordsToFetch = [];

    cachedDataResults.forEach((cachedData, index) => {
      if (cachedData) {
        console.log(`Cache hit for keyword: ${keywords[index]} with pageToken: ${actualPageToken}`);
        const data = JSON.parse(cachedData);
        cachedVideos = cachedVideos.concat(data.videoDetails.filter(video => !viewedVideos.includes(video.id)));
      } else {
        console.log(`Cache miss for keyword: ${keywords[index]} with pageToken: ${actualPageToken}`);
        keywordsToFetch.push(keywords[index]);
      }
    });

    // Step 3: Fetch videos for keywords with cache miss
    if (keywordsToFetch.length > 0) {
      for (const keyword of keywordsToFetch) {
        console.log(`Fetching videos for keyword: ${keyword} from YouTube API`);
        const result = await fetchVideosFromYouTube([keyword], actualPageToken, topic);
        const videoDetails = result.videoDetails;
        const nextPageToken = result.nextPageToken || '';

        console.log(`Fetched ${videoDetails.length} videos for keyword: ${keyword}`);

        // Store fetched videos in cache
        redisClient.setEx(`videos_${keyword}_${actualPageToken}`, 86400, JSON.stringify({ videoDetails, nextPageToken }));
        console.log(`Stored ${videoDetails.length} videos in cache for keyword: ${keyword} with pageToken: ${actualPageToken}`);

        // Add fetched videos to cachedVideos
        cachedVideos = cachedVideos.concat(videoDetails.filter(video => !viewedVideos.includes(video.id)));
      }
    } else {
      console.log(`All keywords were cache hits.`);
    }

    // Shuffle videos to ensure a mix of topics
    cachedVideos.sort(() => 0.5 - Math.random());
    console.log(`Returning ${cachedVideos.length} videos to client.`);

    // Step 4: Return combined videos and nextPageToken
    res.json({ videos: cachedVideos, nextPageToken: '' });
  } catch (error) {
    console.error('Error fetching videos:', error);
    res.status(500).send('Error fetching videos');
  }
});

// Avvio del server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});