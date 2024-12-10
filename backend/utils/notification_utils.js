function getNextNotificationDelay(lastDelay) {
  if (!lastDelay) {
    return 6 * 60 * 60 * 1000; // 6 ore in millisecondi
  }
  
  if (lastDelay < 24 * 60 * 60 * 1000) {
    return lastDelay * 2; // Raddoppia l'intervallo
  }
  
  return 24 * 60 * 60 * 1000; // Massimo 24 ore
}

module.exports = { getNextNotificationDelay }; 