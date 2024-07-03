const apiKeys = [
    { key: 'AIzaSyAG87ey3qFYA9nDsLgx6_Q3neAi0m7RekI', quota: 10000 }
  ];
  let currentKeyIndex = 0;
  
  const getCurrentApiKey = () => {
    return apiKeys[currentKeyIndex].key;
  };
  
  module.exports = {
    getCurrentApiKey
  };