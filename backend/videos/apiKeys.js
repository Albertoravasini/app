const apiKeys = [
    { key: 'AIzaSyD-rKsZ17kf3Ei-WnMs1wuHN8XpyjjEDqA', quota: 10000 }
  ];
  let currentKeyIndex = 0;
  
  const getCurrentApiKey = () => {
    return apiKeys[currentKeyIndex].key;
  };
  
  module.exports = {
    getCurrentApiKey
  };