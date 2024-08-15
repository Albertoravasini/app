const { exec } = require('child_process');
const { promisify } = require('util');
const execPromise = promisify(exec); // Correzione dell'importazione di execPromise
const puppeteer = require('puppeteer');
const fs = require('fs');

async function extractVideoText(videoUrl) {
  try {
    console.log(`Extracting video text for URL: ${videoUrl}`);

    const browser = await puppeteer.launch({
      headless: true, // Imposta a false per debug visuale
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    const page = await browser.newPage();

    // Naviga verso la pagina del video su YouTube
    await page.goto(videoUrl, { waitUntil: 'networkidle2' });

    // Aspetta che l'elemento del video o dei sottotitoli sia presente
    await page.waitForSelector('video', { timeout: 60000 });

    // Verifica se è richiesto il login e, se necessario, esegui l'accesso
    const loginButton = await page.$('a[href*="accounts.google.com"]');
    if (loginButton) {
      console.log('Login required, performing login...');
      await page.click('a[href*="accounts.google.com"]');

      // Inserisci qui il codice per gestire il login tramite Puppeteer
      // Dovrai utilizzare le credenziali di Google e completare il processo di autenticazione
      // Potresti anche voler gestire eventuali captcha qui
    }

    // Controlla la presenza di captcha e gestiscilo se necessario
    const captcha = await page.$('iframe[src*="recaptcha"]');
    if (captcha) {
      console.log('Captcha detected, solving...');
      // Gestisci il captcha qui, ad esempio utilizzando servizi esterni o automazione
    }

    // Ora esegui lo scraping dei sottotitoli utilizzando `yt-dlp`
    const videoId = videoUrl.split('v=')[1];
    const command = `yt-dlp --write-auto-sub --sub-lang it --sub-format vtt --skip-download --output "${videoId}.%(ext)s" ${videoUrl}`;
    await execPromise(command);

    // Leggi il file dei sottotitoli
    const subtitleFile = `${videoId}.it.vtt`;
    if (!fs.existsSync(subtitleFile)) {
      console.error('Subtitle file not found');
      throw new Error('Subtitle file not found');
    }

    const subtitles = fs.readFileSync(subtitleFile, 'utf8');
    const lines = subtitles.split('\n');
    const subtitleData = parseSubtitles(lines);

    fs.unlinkSync(subtitleFile); // Elimina il file dei sottotitoli

    await browser.close();
    return subtitleData;
  } catch (error) {
    console.error('Error extracting subtitles:', error);
    throw error;
  }
}

function parseSubtitles(lines) {
  const subtitleData = [];
  let currentSubtitle = {};
  let lastWordsSet = new Set();
  let previousLine = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    if (line === '' || line.startsWith('WEBVTT') || line.match(/^\d+$/)) continue;

    if (line.includes('-->')) {
      const [start, end] = line.split(' --> ');
      if (start && end) {
        currentSubtitle = { start, end, text: '' };
      }
    } else if (currentSubtitle && currentSubtitle.start && currentSubtitle.end) {
      const cleanLine = line.replace(/<\/?[^>]+(>|$)/g, '').trim();
      if (previousLine !== cleanLine) {
        currentSubtitle.text += `${cleanLine} `;
        previousLine = cleanLine;
      }

      if (lines[i + 1].trim() === '') {
        const words = currentSubtitle.text.trim().split(/\s+/);
        const startTime = parseTimestamp(currentSubtitle.start);
        const endTime = parseTimestamp(currentSubtitle.end);
        const wordDuration = (endTime - startTime) / words.length;

        words.forEach((word, index) => {
          if (!lastWordsSet.has(word) && word.length > 0) {
            const timestamp = startTime + index * wordDuration;
            subtitleData.push({ word, timestamp });
            lastWordsSet.add(word);
          }
        });

        currentSubtitle = {};
        lastWordsSet.clear();
      }
    }
  }
  return subtitleData;
}

function parseTimestamp(timestamp) {
  const parts = timestamp.split(':');
  const hours = parseInt(parts[0], 10);
  const minutes = parseInt(parts[1], 10);
  const seconds = parseFloat(parts[2].replace(',', '.'));
  return hours * 3600 + minutes * 60 + seconds;
}

module.exports = { extractVideoText };