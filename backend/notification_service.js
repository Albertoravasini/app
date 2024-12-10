// notification_service.js

/**
 * notification_service.js
 * 
 * This file encapsulates all notification-related functionalities.
 */

const admin = require('firebase-admin');
const { getNextNotificationDelay } = require('./utils/notification_utils');

class NotificationService {
  async schedulePushNotification(uid, token, db, redisClient) {
    try {
      const lastAccess = await redisClient.get(`user_last_access_${uid}`);
      if (!lastAccess) return;

      let lastNotificationDelay = await redisClient.get(`user_last_notification_delay_${uid}`);
      lastNotificationDelay = lastNotificationDelay ? parseInt(lastNotificationDelay) : null;

      const nextNotificationDelay = getNextNotificationDelay(lastNotificationDelay);

      // Recupera info utente
      const userDoc = await db.collection('users').doc(uid).get();
      const userData = userDoc.exists ? userDoc.data() : null;
      const userName = userData?.name || 'Amico';

      // Personalizza il messaggio in base al tempo trascorso
      const messages = {
        6: [  // 6 ore
          {
            title: '🧠 Missing Out on Learning?',
            body: `While others scroll mindlessly, you could be learning something amazing.`
          },
          {
            title: '💫 Quick Learning Break?',
            body: 'Turn your scrolling time into growth time. New content waiting for you.'
          }
        ],
        12: [  // 12 ore
          {
            title: '🎯 Feed Your Mind',
            body: 'Transform your scroll breaks into power moves. Your personalized learning feed is ready.'
          },
          {
            title: '⚡ Procrastinating?',
            body: 'Turn FOMO into GOMO - Growth Over Missing Out. Your learning feed is fresh.'
          }
        ],
        24: [  // 24 ore
          {
            title: '🔥 Feeling Unproductive?',
            body: 'Others are learning while scrolling. Jump back into your educational feed.'
          },
          {
            title: '✨ Miss That Learning Dopamine?',
            body: 'Get your daily dose of smart scrolling. New content waiting for you.'
          }
        ]
      };

      const hoursElapsed = nextNotificationDelay / (1000 * 60 * 60);
      const messageKey = Object.keys(messages)
        .map(Number)
        .find(key => hoursElapsed <= key) || 24;
      
      const randomMessage = messages[messageKey][Math.floor(Math.random() * messages[messageKey].length)];

      // Programma la notifica evitando orari notturni
      await this.scheduleNotification(token, randomMessage.title, randomMessage.body, nextNotificationDelay);

      await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay);

    } catch (error) {
      console.error('Errore nella programmazione della notifica:', error);
    }
  }

  async scheduleNotification(token, title, body, delay) {
    const sendTime = new Date(Date.now() + delay);
    const hours = sendTime.getHours();

    // Evita le notifiche tra le 22:00 e le 08:00
    if (hours >= 22 || hours < 8) {
      const nextMorning = new Date(sendTime);
      nextMorning.setHours(8, 0, 0, 0);
      if (hours >= 22) {
        nextMorning.setDate(nextMorning.getDate() + 1);
      }
      delay = nextMorning.getTime() - Date.now();
    }

    setTimeout(async () => {
      try {
        await admin.messaging().send({
          token,
          notification: { title, body },
          android: {
            priority: 'high',
            notification: {
              channelId: 'learning_reminders',
              sound: 'default'
            }
          },
          apns: {
            payload: {
              aps: {
                sound: 'default'
              }
            }
          }
        });
      } catch (error) {
        console.error('Errore nell\'invio della notifica:', error);
      }
    }, delay);
  }
}

module.exports = NotificationService;