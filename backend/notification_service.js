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
    this.TIME_ZONE = 'Europe/Rome';
    this.TIME_FORMAT = {
      timeZone: 'Europe/Rome',
      hour12: false,
      hour: 'numeric',
      minute: 'numeric',
      month: 'numeric',
      day: 'numeric',
      year: 'numeric'
    };
  }

  async scheduleNotification(token, title, body, delay) {
    try {
      const CET_OFFSET = 1; // Fuso orario CET (Italia)
      
      const currentTimeCET = new Date(Date.now() + (CET_OFFSET * 60 * 60 * 1000));
      const scheduledTimeCET = new Date(Date.now() + delay + (CET_OFFSET * 60 * 60 * 1000));
      
      console.log(`Current time:
      - CET: ${currentTimeCET.toLocaleString('it-IT', this.TIME_FORMAT)}`);

      // Controlla se l'orario programmato è tra le 22:00 e le 8:00 CET
      const scheduledHour = scheduledTimeCET.getHours();
      
      if (scheduledHour >= 22 || scheduledHour < 8) {
        // Calcola le 8:00 CET del giorno appropriato
        const nextMorning = new Date(scheduledTimeCET);
        nextMorning.setHours(8, 0, 0, 0);
        
        if (scheduledHour >= 22) {
          nextMorning.setDate(nextMorning.getDate() + 1);
        }
        
        // Calcola il nuovo delay per arrivare alle 8:00 CET
        delay = nextMorning.getTime() - currentTimeCET.getTime();
        
        console.log(`Notification rescheduled:
        - Original time (CET): ${scheduledTimeCET.toLocaleString('it-IT', this.TIME_FORMAT)}
        - New time (CET): ${nextMorning.toLocaleString('it-IT', this.TIME_FORMAT)}`);
      }

      console.log(`Notification scheduled for:
      - CET: ${new Date(Date.now() + delay).toLocaleString('it-IT', this.TIME_FORMAT)}
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
          CET time of sending: ${new Date().toLocaleString('it-IT', this.TIME_FORMAT)}`);
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
      
      // Seleziona un messaggio casuale
      const randomIndex = Math.floor(Math.random() * messages.length);
      const selectedMessage = messages[randomIndex];
      console.log('Selected message index:', randomIndex);

      // Schedule notification with the single selected message
      await this.scheduleNotification(token, selectedMessage.title, selectedMessage.body, nextNotificationDelay);
      
      // Save new delay only after successful scheduling
      await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay.toString(), 'EX', 7 * 24 * 60 * 60); // Expires in 7 days
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
          title: '🧠 Ti stai perdendo qualcosa?',
          body: `Mentre altri scorrono senza meta, tu potresti imparare qualcosa di straordinario.`
        },
        {
          title: '💫 Pausa di apprendimento?',
          body: 'Trasforma il tuo tempo in crescita personale. Nuovi contenuti ti aspettano.'
        }
      ],
      12: [  // 12 ore
        {
          title: '🎯 Nutri la tua mente',
          body: 'Trasforma le tue pause in momenti di crescita. Il tuo feed personalizzato è pronto.'
        },
        {
          title: '⚡ Stai procrastinando?',
          body: 'Non perdere l\'occasione di imparare. Il tuo feed di apprendimento è aggiornato.'
        }
      ],
      24: [  // 24 ore
        {
          title: '🔥 Ti senti improduttivo?',
          body: 'Altri stanno imparando mentre scrollano. Torna al tuo feed educativo.'
        },
        {
          title: '✨ Ti manca quella sensazione?',
          body: 'Ottieni la tua dose quotidiana di apprendimento intelligente. Nuovi contenuti ti aspettano.'
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

  async sendSpecificNotification(token, type, senderName) {
    let title, body;
    
    switch(type) {
      case 'teacher_message':
        title = '📚 Nuovo messaggio dal docente';
        body = `${senderName} ti ha inviato un messaggio`;
        break;
      case 'student_message':
        title = '👨‍🎓 Nuovo messaggio da studente';
        body = `${senderName} ti ha inviato un messaggio`;
        break;
      case 'comment_reply':
        title = '💬 Nuovo commento';
        body = `${senderName} ha risposto al tuo commento`;
        break;
      default:
        return;
    }

    try {
      await admin.messaging().send({
        token: token,
        notification: {
          title: title,
          body: body
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'social_interactions'
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
      console.error('Error sending specific notification:', error);
    }
  }
}

module.exports = NotificationService;