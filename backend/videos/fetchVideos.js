const axios = require('axios');
const { getCurrentApiKey } = require('./apiKeys');

const fetchVideosFromYouTube = async (keywords, pageToken = '', topic) => {
  const apiKey = getCurrentApiKey();
  const queries = keywords.join('|'); // Combine keywords with 'or' operator

  const params = {
    part: 'snippet',
    q: queries,
    key: apiKey,
    maxResults: 50,
    type: 'video',
    pageToken: pageToken || ''
  };

  if (topic === 'Attualità') {
    params.publishedAfter = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString();
  }

  const response = await axios.get('https://www.googleapis.com/youtube/v3/search', { params });

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
  return { videoDetails, nextPageToken: response.data.nextPageToken };
};

module.exports = {
  fetchVideosFromYouTube
};