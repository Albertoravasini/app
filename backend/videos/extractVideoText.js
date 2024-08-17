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

        const captions = captionsResponse.data.items.filter(caption => caption.snippet.language === 'it');

        if (captions.length === 0) {
            throw new Error('No Italian subtitles found');
        }

        const subtitleId = captions[0].id;

        // Recupera il contenuto dei sottotitoli
        const subtitleContentResponse = await youtube.captions.download({
            id: subtitleId,
            tfmt: 'vtt'
        });

        const subtitles = subtitleContentResponse.data;
        return processSubtitles(subtitles);
    } catch (error) {
        console.error('Error extracting subtitles:', error);
        throw error;
    }
}

function processSubtitles(subtitles) {
    const lines = subtitles.split('\n');
    const subtitleData = [];
    // ... processing logic remains the same
    return subtitleData;
}

module.exports = { extractVideoText };