const retryWithDelay = async (fn, retries, delay) => {
    let lastError;
    for (let i = 0; i < retries; i++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error;
        console.error(`Attempt ${i + 1} failed: ${error.message}. Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    throw lastError;
  };
  
  module.exports = {
    retryWithDelay
  };