const apiKeys = [
    { key: 'AIzaSyCn_ljinSlIUIxIUJy2RurQ_Oo6wbphr7E', quota: 10000 }
  ];
  let currentKeyIndex = 0;
  
  const getCurrentApiKey = () => {
    return apiKeys[currentKeyIndex].key;
  };
  
  module.exports = {
    getCurrentApiKey
  };