const { getSubtitles } = require('youtube-captions-scraper');

async function extractVideoText(videoUrl) {
    try {
        const videoId = videoUrl.split('v=')[1];
        console.log(`Extracting subtitles for video ID: ${videoId}`);

        const subtitles = await getSubtitles({
            videoID: videoId, // YouTube video ID
            lang: 'it'        // ISO 639-1 code for language (Italian)
        });

        const subtitleData = subtitles.map(subtitle => {
            const startTime = parseFloat(subtitle.start);
            return {
                word: subtitle.text,
                timestamp: startTime
            };
        });

        console.log(`Total subtitles extracted: ${subtitleData.length}`);
        return subtitleData;

    } catch (error) {
        console.error('Error extracting subtitles:', error);
        throw error;
    }
}

module.exports = { extractVideoText };