const axios = require('axios');
const { getCurrentApiKey } = require('./apiKeys');

const fetchVideosFromYouTube = async (keywords, pageToken = '', topic) => {
  const apiKey = getCurrentApiKey();

  const videoDetailsPromises = keywords.map(async (keyword) => {
    const params = {
      part: 'snippet',
      q: keyword,
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
    return videoDetails;
  });

  const allVideoDetails = await Promise.all(videoDetailsPromises);
  const combinedVideoDetails = allVideoDetails.flat();

  // Filtrare i video non utili prima di inviare la risposta
  const filteredVideoDetails = combinedVideoDetails.filter(video => {
    return video.statistics.viewCount > 1000; // Esempio: solo video con più di 1000 visualizzazioni
  });

  console.log(`Filtrati ${filteredVideoDetails.length} video utili da ${combinedVideoDetails.length} video recuperati`);

  return { videoDetails: filteredVideoDetails, nextPageToken: '' };
};

module.exports = {
  fetchVideosFromYouTube
};