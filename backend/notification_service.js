// notification_service.js

/**
 * notification_service.js
 * 
 * This file encapsulates all notification-related functionalities.
 */

const admin = require('firebase-admin');

/**
 * Sends a push notification to a specific device.
 * @param {string} token - The device token.
 * @param {string} title - The notification title.
 * @param {string} body - The notification body.
 */
async function sendPushNotification(token, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message: ${response}`);
  } catch (error) {
    console.error(`Error sending message to token ${token}:`, error);
  }
}

/**
 * Calculates the next notification delay using exponential backoff.
 * @param {number|null} lastNotificationDelay - The last delay in milliseconds.
 * @returns {number} - The next delay in milliseconds.
 */
function getNextNotificationDelay(lastNotificationDelay) {
  if (lastNotificationDelay == null) {
    return 6 * 60 * 60 * 1000; // 6 hours in milliseconds
  } else if (lastNotificationDelay < 24 * 60 * 60 * 1000) {
    return lastNotificationDelay * 2; // Double the interval
  } else {
    return 24 * 60 * 60 * 1000; // Maximum 24 hours in milliseconds
  }
}

/**
 * Schedules a push notification with a specified delay, avoiding nighttime hours.
 * @param {string} token - The device token.
 * @param {string} title - The notification title.
 * @param {string} body - The notification body.
 * @param {number} delay - The delay in milliseconds.
 */
function scheduleNotification(token, title, body, delay) {
  let sendTime = Date.now() + delay;
  let sendDate = new Date(sendTime);
  let hours = sendDate.getHours();

  // If the time is between 10 PM and 8 AM, postpone to the next 8 AM
  if (hours >= 22 || hours < 8) {
    let nextMorning = new Date(sendDate);
    if (hours >= 22) {
      // Add a day if it's after 10 PM
      nextMorning.setDate(nextMorning.getDate() + 1);
    }
    nextMorning.setHours(8, 0, 0, 0);
    delay = nextMorning.getTime() - Date.now();
  }

  console.log(`Scheduling notification: "${title}" to be sent after ${delay / 1000} seconds`);

  setTimeout(() => {
    console.log(`Sending notification: "${title}" now`);
    sendPushNotification(token, title, body);
  }, delay);
}

/**
 * Schedules a push notification for a user based on their last notification delay.
 * @param {string} uid - The user ID.
 * @param {string} token - The device token.
 * @param {FirebaseFirestore.Firestore} db - Firestore instance.
 * @param {RedisClientType} redisClient - Redis client instance.
 */
async function schedulePushNotification(uid, token, db, redisClient) {
  console.log(`Scheduling notifications for user ${uid} with token ${token}`);
  const lastAccess = await redisClient.get(`user_last_access_${uid}`);

  if (!lastAccess) {
    console.log(`No last access time found for user ${uid}`);
    return;
  }

  console.log(`Last access for user ${uid}: ${lastAccess}`);

  // Get the last notification delay
  let lastNotificationDelay = await redisClient.get(`user_last_notification_delay_${uid}`);
  lastNotificationDelay = lastNotificationDelay ? parseInt(lastNotificationDelay) : null;

  // Calculate the next notification delay
  const nextNotificationDelay = getNextNotificationDelay(lastNotificationDelay);

  // Save the next notification delay
  await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay);

  // Retrieve user information to personalize the notification
  let userName = 'Amico';
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      userName = userData.name || 'Amico';
    }
  } catch (error) {
    console.error(`Error fetching user data for uid ${uid}:`, error);
  }

  // Customize the notification message
  const notificationTitle = `⏰ Time’s Ticking!`;
  const notificationBody = `Don’t let another minute go to waste. Enhance your skills now! 💡📱`;

  // Schedule the notification
  scheduleNotification(
    token,
    notificationTitle,
    notificationBody,
    nextNotificationDelay
  );
}

module.exports = {
  sendPushNotification,
  schedulePushNotification,
};