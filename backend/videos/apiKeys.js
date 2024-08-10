const apiKeys = [
  { key: 'AIzaSyCVhnUS_EZhObiGUd5hpGpo6AwP9o5DUi4', quota: 10000, used: 0 },
  { key: 'AIzaSyAG87ey3qFYA9nDsLgx6_Q3neAi0m7RekI', quota: 10000, used: 0 },
  { key: 'AIzaSyCn_ljinSlIUIxIUJy2RurQ_Oo6wbphr7E', quota: 10000, used: 0 },
  // Aggiungi altre chiavi API qui
];

let currentKeyIndex = 0;

const getCurrentApiKey = () => {
  return apiKeys[currentKeyIndex].key;
};

const updateApiKeyUsage = (usage) => {
  apiKeys[currentKeyIndex].used += usage;
  if (apiKeys[currentKeyIndex].used >= apiKeys[currentKeyIndex].quota) {
    currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
    console.log(`Quota reached. Switching to API key: ${getCurrentApiKey()}`);
  }
};

module.exports = {
  getCurrentApiKey,
  updateApiKeyUsage
};