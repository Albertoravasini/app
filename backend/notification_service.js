// notification_service.js

/**
 * notification_service.js
 * 
 * This file encapsulates all notification-related functionalities.
 */

const admin = require('firebase-admin');
const { getNextNotificationDelay } = require('./utils/notification_utils');

class NotificationService {
  constructor() {
    this.TIME_ZONE = 'America/New_York';
    this.TIME_FORMAT = {
      timeZone: 'America/New_York',
      hour12: true,
      hour: 'numeric',
      minute: 'numeric',
      month: 'numeric',
      day: 'numeric',
      year: 'numeric'
    };
  }

  async scheduleNotification(token, title, body, delay) {
    try {
      const EST_OFFSET = -5; // Fuso orario EST (New York)
      
      const currentTimeEST = new Date(Date.now() + (EST_OFFSET * 60 * 60 * 1000));
      const scheduledTimeEST = new Date(Date.now() + delay + (EST_OFFSET * 60 * 60 * 1000));
      
      console.log(`Current time:
      - EST: ${currentTimeEST.toLocaleString('en-US', this.TIME_FORMAT)}`);

      // Controlla se l'orario programmato è tra le 10:00 PM e le 8:00 AM EST
      const scheduledHour = scheduledTimeEST.getHours();
      
      if (scheduledHour >= 22 || scheduledHour < 8) {
        // Calcola le 8:00 AM EST del giorno appropriato
        const nextMorning = new Date(scheduledTimeEST);
        nextMorning.setHours(8, 0, 0, 0);
        
        if (scheduledHour >= 22) {
          nextMorning.setDate(nextMorning.getDate() + 1);
        }
        
        // Calcola il nuovo delay per arrivare alle 8:00 AM EST
        delay = nextMorning.getTime() - currentTimeEST.getTime();
        
        console.log(`Notification rescheduled:
        - Original time (EST): ${scheduledTimeEST.toLocaleString('en-US', this.TIME_FORMAT)}
        - New time (EST): ${nextMorning.toLocaleString('en-US', this.TIME_FORMAT)}`);
      }

      console.log(`Notification scheduled for:
      - EST: ${new Date(Date.now() + delay).toLocaleString('en-US', this.TIME_FORMAT)}
      - Delay: ${delay / (1000 * 60 * 60)} hours`);

      setTimeout(async () => {
        try {
          await admin.messaging().send({
            token,
            notification: { title, body },
            android: {
              priority: 'high',
              notification: {
                channelId: 'learning_reminders'
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
          console.log(`Notification sent successfully to ${token.substring(0, 10)}...
          EST time of sending: ${new Date().toLocaleString('en-US', this.TIME_FORMAT)}`);
        } catch (error) {
          console.error('Error sending notification:', error);
        }
      }, delay);

    } catch (error) {
      console.error('Error scheduling notification:', error);
    }
  }

  async schedulePushNotification(uid, token, db, redisClient) {
    try {
      console.log('Starting notification scheduling for uid:', uid);
      
      // Force reset - Remove after testing
      await redisClient.del(`user_last_notification_delay_${uid}`);
      console.log('Forced reset of previous delay');
      
      // Check last delay used
      let lastNotificationDelay = await redisClient.get(`user_last_notification_delay_${uid}`);
      console.log('Last delay:', lastNotificationDelay ? `${parseInt(lastNotificationDelay)/3600000} hours` : 'none');

      // Calculate next delay
      const nextNotificationDelay = this.getNextNotificationDelay(lastNotificationDelay ? parseInt(lastNotificationDelay) : null);
      console.log('Next delay calculated:', nextNotificationDelay/3600000, 'hours');

      // Choose appropriate message
      const hoursDelay = nextNotificationDelay / (1000 * 60 * 60);
      const messageKey = hoursDelay <= 6 ? 6 : hoursDelay <= 12 ? 12 : 24;
      const messages = this.getNotificationMessages(messageKey);
      
      // Assicuriamoci di selezionare un solo messaggio casuale
      const randomIndex = Math.floor(Math.random() * messages.length);
      const selectedMessage = messages[randomIndex];
      console.log('Selected message index:', randomIndex);

      // Schedule notification with the single selected message
      await this.scheduleNotification(token, selectedMessage.title, selectedMessage.body, nextNotificationDelay);
      
      // Save new delay
      await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay.toString());
      console.log('New delay saved in Redis:', nextNotificationDelay/3600000, 'hours');

    } catch (error) {
      console.error('Error scheduling notification:', error);
    }
  }

  getNotificationMessages(hours) {
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
    return messages[hours] || messages[24];
  }

  getNextNotificationDelay(lastDelay) {
    console.log('Calculating next delay. Last delay:', lastDelay ? `${lastDelay/3600000} hours` : 'none');
    
    if (!lastDelay) {
      console.log('First access, setting 6 hours');
      return 6 * 60 * 60 * 1000; // 6 hours
    }
    
    if (lastDelay < 24 * 60 * 60 * 1000) {
      const newDelay = lastDelay * 2;
      console.log(`Doubling delay from ${lastDelay/3600000} to ${newDelay/3600000} hours`);
      return newDelay;
    }
    
    console.log('Maximum delay reached, keeping 24 hours');
    return 24 * 60 * 60 * 1000;
  }
}

module.exports = NotificationService;