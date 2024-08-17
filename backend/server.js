const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const { fetchVideosFromYouTube } = require('./videos/fetchVideos');
const compression = require('compression');
const admin = require('firebase-admin');
const { extractVideoText } = require('./videos/extractVideoText');
const { OAuth2Client } = require('google-auth-library');

const app = express();
const port = process.env.PORT || 3000;

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

// Configurazione OAuth2
const CLIENT_ID = '666035353608-51dreihqbgdcbk17ga7ijs5c1sv8rb9q.apps.googleusercontent.com';
const CLIENT_SECRET = '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';
const REDIRECT_URL = 'https://justlearnapp.com/oauth2callback';

const oauth2Client = new OAuth2Client(CLIENT_ID, CLIENT_SECRET, REDIRECT_URL);

app.get('/auth', (req, res) => {
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: ['https://www.googleapis.com/auth/youtube.force-ssl']
  });
  res.redirect(authUrl);
});

app.get('/oauth2callback', async (req, res) => {
  const code = req.query.code;
  try {
    const { tokens } = await oauth2Client.getToken(code);
    oauth2Client.setCredentials(tokens);
    // Salva i token in una sessione o nel database per futuri utilizzi
    res.redirect(`/extract_video_text?accessToken=${tokens.access_token}`);
  } catch (error) {
    console.error('Error during OAuth2 callback:', error);
    res.status(500).send('Authentication failed');
  }
});

app.post('/new_videos', async (req, res) => {
  const { keywords, viewedVideos, pageToken, topic } = req.body;
  const actualPageToken = pageToken || '';

  console.log(`Request received with keywords: ${keywords.join(', ')}, pageToken: ${actualPageToken}, topic: ${topic}`);

  try {
    const cachedDataPromises = keywords.map(keyword => redisClient.get(`videos_${keyword}_${actualPageToken}`));
    const cachedDataResults = await Promise.all(cachedDataPromises);

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

    if (keywordsToFetch.length > 0) {
      for (const keyword of keywordsToFetch) {
        console.log(`Fetching videos for keyword: ${keyword} from YouTube API`);
        const result = await fetchVideosFromYouTube([keyword], actualPageToken, topic);
        const videoDetails = result.videoDetails;
        const nextPageToken = result.nextPageToken || '';

        console.log(`Fetched ${videoDetails.length} videos for keyword: ${keyword}`);

        redisClient.setEx(`videos_${keyword}_${actualPageToken}`, 86400, JSON.stringify({ videoDetails, nextPageToken }));
        console.log(`Stored ${videoDetails.length} videos in cache for keyword: ${keyword} with pageToken: ${actualPageToken}`);

        cachedVideos = cachedVideos.concat(videoDetails.filter(video => !viewedVideos.includes(video.id)));
      }
    } else {
      console.log(`All keywords were cache hits.`);
    }

    cachedVideos.sort(() => 0.5 - Math.random());
    console.log(`Returning ${cachedVideos.length} videos to client.`);

    res.json({ videos: cachedVideos, nextPageToken: '' });
  } catch (error) {
    console.error('Error fetching videos:', error);
    res.status(500).send('Error fetching videos');
  }
});

app.post('/extract_video_text', async (req, res) => {
  const { videoUrl, accessToken } = req.body;

  try {
    const subtitles = await extractVideoText(videoUrl, accessToken);
    res.json({ subtitles });
  } catch (error) {
    console.error('Error extracting video text:', error);
    res.status(500).json({ error: 'Failed to extract video text' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});