const { google } = require('googleapis');
const { getCurrentApiKey, updateApiKeyUsage } = require('./apiKeys');
const { OAuth2Client } = require('google-auth-library');

const CLIENT_ID = '666035353608-51dreihqbgdcbk17ga7ijs5c1sv8rb9q.apps.googleusercontent.com';
const CLIENT_SECRET = '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';
const REDIRECT_URL = 'https://justlearnapp.com/oauth2callback';  // Assicurati che corrisponda a quello impostato su Google Console

const oauth2Client = new OAuth2Client(CLIENT_ID, CLIENT_SECRET, REDIRECT_URL);

async function extractVideoText(videoUrl, accessToken) {
    try {
        console.log(`Extracting video text for URL: ${videoUrl}`);

        const videoId = videoUrl.split('v=')[1];
        const youtube = google.youtube({
            version: 'v3',
            auth: oauth2Client
        });

        oauth2Client.setCredentials({ access_token: accessToken });

        // Ottieni i sottotitoli del video usando l'API di YouTube
        const captionsResponse = await youtube.captions.list({
            part: 'snippet',
            videoId: videoId
        });

        // Filtra i sottotitoli per lingua italiana (it)
        const captions = captionsResponse.data.items.filter(caption => caption.snippet.language === 'it');

        if (captions.length === 0) {
            console.error('No Italian subtitles found');
            throw new Error('No Italian subtitles found');
        }

        const subtitleId = captions[0].id;

        // Recupera il contenuto dei sottotitoli
        const subtitleContentResponse = await youtube.captions.download({
            id: subtitleId,
            tfmt: 'vtt' // Richiedi il formato VTT
        });

        const subtitles = subtitleContentResponse.data;

        // Elaborazione del contenuto VTT
        const lines = subtitles.split('\n');
        const subtitleData = [];
        let currentSubtitle = {};
        let lastWordsSet = new Set();
        let previousLine = '';

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();

            if (line === '' || line.startsWith('WEBVTT') || line.match(/^\d+$/)) {
                continue;
            }

            if (line.includes('-->')) {
                const [start, end] = line.split(' --> ');
                currentSubtitle = { start, end, text: '' };
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

                    if (!isNaN(startTime) && !isNaN(endTime)) {
                        const wordDuration = (endTime - startTime) / words.length;
                        for (let index = 0; index < words.length; index++) {
                            const word = words[index];
                            if (!lastWordsSet.has(word) && word.length > 0) {
                                const timestamp = startTime + index * wordDuration;
                                subtitleData.push({
                                    word: word,
                                    timestamp: timestamp
                                });
                                lastWordsSet.add(word);
                            }
                        }
                    }

                    currentSubtitle = {};
                    lastWordsSet.clear();
                }
            }
        }

        return subtitleData;

    } catch (error) {
        console.error('Error extracting subtitles:', error);
        throw error;
    }
}

function parseTimestamp(timestamp) {
    const parts = timestamp.split(':');
    const hours = parseInt(parts[0], 10);
    const minutes = parseInt(parts[1], 10);
    const seconds = parseFloat(parts[2].replace(',', '.'));
    return hours * 3600 + minutes * 60 + seconds;
}

module.exports = { extractVideoText };