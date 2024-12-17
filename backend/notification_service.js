// notification_service.js

/**
 * notification_service.js
 * 
 * This file encapsulates all notification-related functionalities.
 */

const admin = require('firebase-admin');
const { getNextNotificationDelay } = require('./utils/notification_utils');

class NotificationService {
  async scheduleNotification(token, title, body, delay) {
    try {
      // Calcola l'orario effettivo di invio
      const scheduledTime = new Date(Date.now() + delay);
      console.log(`Programmazione notifica:
      - Orario attuale: ${new Date().toLocaleString('it-IT')}
      - Delay: ${delay / (1000 * 60 * 60)} ore
      - Orario previsto: ${scheduledTime.toLocaleString('it-IT')}`);

      // Usa l'ora del server come base e aggiungi 1 ora (assumendo Italia)
      const userTime = new Date(scheduledTime.getTime() + (1 * 60 * 60 * 1000)); // UTC+1 per Italia
      const userHours = userTime.getHours();

      // Evita le notifiche tra le 22:00 e le 08:00
      if (userHours >= 22 || userHours < 8) {
        const nextMorning = new Date(userTime);
        nextMorning.setHours(8, 0, 0, 0);
        if (userHours >= 22) {
          nextMorning.setDate(nextMorning.getDate() + 1);
        }
        delay = nextMorning.getTime() - Date.now();
        console.log(`Orario aggiustato per evitare la notte: ${new Date(Date.now() + delay).toLocaleString('it-IT')}`);
      }

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
          console.log(`Notifica inviata con successo a ${token.substring(0, 10)}...`);
        } catch (error) {
          console.error('Errore nell\'invio della notifica:', error);
        }
      }, delay);

    } catch (error) {
      console.error('Errore nella programmazione della notifica:', error);
    }
  }

  async schedulePushNotification(uid, token, db, redisClient) {
    try {
      console.log('Inizio schedulazione notifica per uid:', uid);
      
      // RESET FORZATO - Rimuovi dopo il test
      await redisClient.del(`user_last_notification_delay_${uid}`);
      console.log('Reset forzato del delay precedente');
      
      // Controlla l'ultimo delay utilizzato
      let lastNotificationDelay = await redisClient.get(`user_last_notification_delay_${uid}`);
      console.log('Ultimo delay:', lastNotificationDelay ? `${parseInt(lastNotificationDelay)/3600000} ore` : 'nessuno');

      // Calcola il prossimo delay
      const nextNotificationDelay = this.getNextNotificationDelay(lastNotificationDelay ? parseInt(lastNotificationDelay) : null);
      console.log('Prossimo delay calcolato:', nextNotificationDelay/3600000, 'ore');

      // Scegli il messaggio appropriato
      const hoursDelay = nextNotificationDelay / (1000 * 60 * 60);
      const messageKey = hoursDelay <= 6 ? 6 : hoursDelay <= 12 ? 12 : 24;
      const messages = this.getNotificationMessages(messageKey);
      const randomMessage = messages[Math.floor(Math.random() * messages.length)];

      // Programma la notifica
      await this.scheduleNotification(token, randomMessage.title, randomMessage.body, nextNotificationDelay);
      
      // Salva il nuovo delay
      await redisClient.set(`user_last_notification_delay_${uid}`, nextNotificationDelay.toString());
      console.log('Nuovo delay salvato in Redis:', nextNotificationDelay/3600000, 'ore');

    } catch (error) {
      console.error('Errore nella programmazione della notifica:', error);
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
    console.log('Calcolo prossimo delay. Ultimo delay:', lastDelay ? `${lastDelay/3600000} ore` : 'nessuno');
    
    if (!lastDelay) {
      console.log('Primo accesso, imposto 6 ore');
      return 6 * 60 * 60 * 1000; // 6 ore
    }
    
    if (lastDelay < 24 * 60 * 60 * 1000) {
      const newDelay = lastDelay * 2;
      console.log(`Raddoppio il delay da ${lastDelay/3600000} a ${newDelay/3600000} ore`);
      return newDelay;
    }
    
    console.log('Delay massimo raggiunto, mantengo 24 ore');
    return 24 * 60 * 60 * 1000;
  }
}

module.exports = NotificationService;