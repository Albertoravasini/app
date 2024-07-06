const axios = require('axios');
const { getCurrentApiKey, updateApiKeyUsage } = require('./apiKeys');

const fetchVideosFromYouTube = async (keywords, pageToken = '', topic) => {
  let apiKey = getCurrentApiKey();

  console.log(`Fetching videos from YouTube for keywords: ${keywords.join(', ')} with pageToken: ${pageToken}`);

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

    let response;
    try {
      response = await axios.get('https://www.googleapis.com/youtube/v3/search', { params });
      updateApiKeyUsage(response.data.items.length); // Aggiorna l'uso della chiave API
    } catch (error) {
      if (error.response && error.response.status === 403) {
        // Se la chiave API ha raggiunto il limite, commuta a una nuova chiave
        apiKey = getCurrentApiKey();
        params.key = apiKey;
        response = await axios.get('https://www.googleapis.com/youtube/v3/search', { params });
        updateApiKeyUsage(response.data.items.length);
      } else {
        throw error;
      }
    }

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

  const filteredVideoDetails = combinedVideoDetails.filter(video => {
    return video.statistics.viewCount > 1000;
  });

  console.log(`Filtered ${filteredVideoDetails.length} useful videos out of ${combinedVideoDetails.length} videos retrieved`);

  return { videoDetails: filteredVideoDetails, nextPageToken: '' };
};

module.exports = {
  fetchVideosFromYouTube
};