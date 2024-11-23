const { PythonShell } = require('python-shell');
const path = require('path');

class Scraper {
  async scrapeArticles(query) {
    return new Promise((resolve, reject) => {
      const options = {
        mode: 'text',
        pythonPath: 'python3',
        pythonOptions: ['-u'],
        scriptPath: path.join(__dirname),
        args: [query]
      };

      console.log('Avvio ContentFetcher con:', {
        scriptPath: options.scriptPath,
        query: query
      });

      let dataString = '';
      let errorString = '';

      const pyshell = new PythonShell('content_fetcher.py', options);

      pyshell.on('message', function (message) {
        dataString += message;
      });

      pyshell.on('stderr', function(stderr) {
        console.log('Debug output:', stderr);
        errorString += stderr;
      });

      pyshell.end(function (err) {
        if (err) {
          console.error('Errore nell\'esecuzione di content_fetcher.py:', err);
          console.error('Output di errore:', errorString);
          resolve([]);
          return;
        }

        try {
          if (dataString.trim()) {
            const results = JSON.parse(dataString);
            console.log(`Trovati ${results.length} risultati da ContentFetcher`);
            resolve(results);
          } else {
            console.log('Nessun risultato trovato da ContentFetcher');
            console.log('Output ricevuto:', dataString);
            resolve([]);
          }
        } catch (error) {
          console.error('Errore nel parsing dei risultati:', error);
          console.error('Output ricevuto:', dataString);
          resolve([]);
        }
      });
    });
  }
}

module.exports = { Scraper }; 