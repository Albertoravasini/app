const axios = require('axios');
const { getCurrentApiKey } = require('./apiKeys');

const fetchVideosFromYouTube = async (keywords, pageToken = '', topic) => {
  const apiKey = getCurrentApiKey();

  // Log the API request details
  console.log(`Fetching videos from YouTube for keywords: ${keywords.join(', ')} with pageToken: ${pageToken}`);

  // Process each keyword individually
  const videoDetailsPromises = keywords.map(async (keyword) => {
    const params = {
      part: 'snippet',
      q: keyword, // Query for a single keyword
      key: apiKey,
      maxResults: 50,
      type: 'video',
      pageToken: pageToken || ''
    };

    if (topic === 'Attualità') {
      params.publishedAfter = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
    }

    const response = await axios.get('https://www.googleapis.com/youtube/v3/search', { params });
    console.log(`Fetched ${response.data.items.length} items from YouTube search for keyword: ${keyword}`);

    const videoDetailsPromises = response.data.items.map(async (item) => {
      const videoId = item.id.videoId;
      const videoResponse = await axios.get('https://www.googleapis.com/youtube/v3/videos', {
        params: {
          part: 'snippet,statistics',
          id: videoId,
          key: apiKey
        }
      });
      return videoResponse.data.items[0];
    });

    const videoDetails = await Promise.all(videoDetailsPromises);
    console.log(`Fetched details for ${videoDetails.length} videos for keyword: ${keyword}`);
    return videoDetails;
  });

  const allVideoDetails = await Promise.all(videoDetailsPromises);
  const combinedVideoDetails = allVideoDetails.flat();

  // Filtrare i video non utili prima di inviare la risposta
  const filteredVideoDetails = combinedVideoDetails.filter(video => {
    return video.statistics.viewCount > 1000; // Esempio: solo video con più di 1000 visualizzazioni
  });

  console.log(`Filtered ${filteredVideoDetails.length} useful videos out of ${combinedVideoDetails.length} videos retrieved`);

  return { videoDetails: filteredVideoDetails, nextPageToken: '' };
};

module.exports = {
  fetchVideosFromYouTube
};