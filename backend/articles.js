// backend/articles.js
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { Scraper } = require('./scrapers/news_scraper_wrapper');

router.post('/get_related_articles', async (req, res) => {
  console.log('1. Ricevuta richiesta per articoli');
  
  try {
    const { videoTitle } = req.body;
    
    if (!videoTitle) {
      console.log('Errore: Titolo video mancante');
      return res.status(400).json({ 
        success: false, 
        message: 'Il titolo del video è richiesto' 
      });
    }

    console.log('2. Ricerca articoli per:', videoTitle);
    
    // Cerca articoli esistenti per questo specifico video
    const articlesRef = admin.firestore()
      .collection('articles')
      .where('videoTitle', '==', videoTitle);
    
    const existingArticles = await articlesRef.get();
    
    // Controlla la validità della cache (24 ore)
    const cacheValidityHours = 24; // Puoi impostare 24 ore o altro
    const now = Date.now();
    const cacheExpiry = now - (cacheValidityHours * 60 * 60 * 1000);
    
    if (!existingArticles.empty) {
      const articles = existingArticles.docs
        .map(doc => ({
          ...doc.data(),
          createdAt: doc.data().createdAt?.toMillis() || 0
        }))
        .filter(article => article.createdAt > cacheExpiry);

      if (articles.length > 0) {
        console.log('3. Trovati articoli validi in cache:', articles.length);
        return res.json({ 
          success: true, 
          data: articles.map(({createdAt, ...article}) => article)
        });
      }
    }
    
    console.log('4. Nessun articolo in cache o cache scaduta, avvio ContentFetcher');
    const scraper = new Scraper();
    const articles = await scraper.scrapeArticles(videoTitle);
    
    console.log('5. Articoli recuperati:', articles.length);
    
    if (articles.length > 0) {
      // Elimina i vecchi articoli per questo video
      const batch = admin.firestore().batch();
      existingArticles.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      // Salva i nuovi articoli
      articles.forEach(article => {
        const docRef = admin.firestore().collection('articles').doc();
        batch.set(docRef, {
          ...article,
          videoTitle,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      console.log('6. Articoli salvati in Firebase');
    } else {
      console.log('Nessun articolo trovato per il video:', videoTitle);
    }
    
    res.json({ success: true, data: articles });
    
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