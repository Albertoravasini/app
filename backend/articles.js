// backend/articles.js
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { Scraper } = require('./scrapers/news_scraper_wrapper');

router.post('/articles/related', async (req, res) => {
  console.log('1. Ricevuta richiesta per articoli');
  
  try {
    const { videoTitle, levelId } = req.body;
    
    if (!videoTitle || !levelId) {
      console.log('Errore: Titolo video o levelId mancante');
      return res.status(400).json({ 
        success: false, 
        message: 'Il titolo del video e levelId sono richiesti' 
      });
    }

    console.log('2. Ricerca articoli per:', videoTitle);
    console.log('Level ID:', levelId);
    
    // Cerca articoli esistenti sia per video che per levelId
    const articlesRef = admin.firestore()
      .collection('articles')
      .where('levelId', '==', levelId);
    
    const existingArticles = await articlesRef.get();
    
    // Controlla la validità della cache (24 ore)
    const cacheValidityHours = 24; // Impostato a 24 ore
    const now = Date.now();
    const cacheExpiry = now - (cacheValidityHours * 60 * 60 * 1000);
    
    if (!existingArticles.empty) {
      const articles = existingArticles.docs
        .map(doc => ({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt?.toMillis() || 0
        }))
        .filter(article => article.createdAt > cacheExpiry);

      if (articles.length > 0) {
        console.log('3. Trovati articoli validi in Firebase:', articles.length);
        return res.json({ 
          success: true, 
          data: articles.map(({createdAt, ...article}) => article)
        });
      }
    }
    
    console.log('4. Nessun articolo valido trovato, avvio ContentFetcher');
    const scraper = new Scraper();
    const newArticles = await scraper.scrapeArticles(videoTitle);
    
    console.log('5. Articoli recuperati:', newArticles.length);
    
    if (newArticles.length > 0) {
      // Elimina solo gli articoli scaduti per questo levelId
      const batch = admin.firestore().batch();
      existingArticles.docs.forEach(doc => {
        const createdAt = doc.data().createdAt?.toMillis() || 0;
        if (createdAt <= cacheExpiry) {
          batch.delete(doc.ref);
        }
      });
      
      // Salva i nuovi articoli
      newArticles.forEach(article => {
        const docRef = admin.firestore().collection('articles').doc();
        batch.set(docRef, {
          ...article,
          videoTitle,
          levelId,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      console.log('6. Nuovi articoli salvati in Firebase con levelId');
    } else {
      console.log('Nessun nuovo articolo trovato per il video:', videoTitle);
    }
    
    res.json({ success: true, data: newArticles });
    
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nel recupero degli articoli',
      error: error.message 
    });
  }
});

module.exports = router;