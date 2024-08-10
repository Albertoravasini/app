const { exec } = require('child_process');
const { promisify } = require('util');
const execPromise = promisify(exec);
const fs = require('fs');

async function extractVideoText(videoUrl) {
    try {
        console.log(`Extracting video text for URL: ${videoUrl}`);

        // Modifica per scaricare i sottotitoli in italiano (codice lingua "it")
        const command = `yt-dlp --write-auto-sub --sub-lang it --sub-format vtt --skip-download --output "%(id)s.%(ext)s" ${videoUrl}`;
        console.log(`Executing command: ${command}`);
        await execPromise(command);

        const videoId = videoUrl.split('v=')[1];
        console.log(`Extracted video ID: ${videoId}`);

        // Cambia il nome del file dei sottotitoli per cercare quello in italiano
        const subtitleFile = `${videoId}.it.vtt`;
        if (!fs.existsSync(subtitleFile)) {
            console.error('Subtitle file not found');
            throw new Error('Subtitle file not found');
        }

        console.log(`Reading subtitle file: ${subtitleFile}`);
        const subtitles = fs.readFileSync(subtitleFile, 'utf8');
        console.log('Subtitle file read successfully');

        const lines = subtitles.split('\n');
        const subtitleData = [];
        let currentSubtitle = {};
        let lastWordsSet = new Set();
        let previousLine = ''; // Per controllare frasi ripetute

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            console.log(`Processing line ${i + 1}: ${line}`);

            if (line === '' || line.startsWith('WEBVTT') || line.match(/^\d+$/)) {
                console.log(`Skipping line ${i + 1}: ${line}`);
                continue;
            }

            if (line.includes('-->')) {
                const [start, end] = line.split(' --> ');
                if (start && end) {
                    console.log(`Found timestamp: start=${start}, end=${end}`);
                    currentSubtitle = { start, end, text: '' };
                } else {
                    console.warn(`Invalid timestamp format on line ${i + 1}: ${line}`);
                }
            } else if (currentSubtitle && currentSubtitle.start && currentSubtitle.end) {
                const cleanLine = line.replace(/<\/?c>|<\/?[^>]+(>|$)/g, '').trim();

                // Controlla se la linea è già stata elaborata in precedenza
                if (previousLine !== cleanLine) {
                    currentSubtitle.text += `${cleanLine} `;
                    previousLine = cleanLine;
                }

                console.log(`Appending text to subtitle: ${currentSubtitle.text}`);

                if (lines[i + 1].trim() === '') {
                    const words = currentSubtitle.text.trim().split(/\s+/);
                    const startTime = parseTimestamp(currentSubtitle.start);
                    const endTime = parseTimestamp(currentSubtitle.end);

                    if (!isNaN(startTime) && !isNaN(endTime)) {
                        console.log(`Processing words with startTime=${startTime}, endTime=${endTime}`);
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
                                console.log(`Added word "${word}" with timestamp ${timestamp}`);
                            }
                        }
                    } else {
                        console.warn(`Invalid timestamps for subtitle: start=${currentSubtitle.start}, end=${currentSubtitle.end}`);
                    }

                    currentSubtitle = {};
                    lastWordsSet.clear(); // Svuota il set alla fine di ogni blocco di sottotitoli
                }
            }
        }

        console.log('Subtitle processing complete');
        console.log(`Total words processed: ${subtitleData.length}`);

        fs.unlinkSync(subtitleFile);
        console.log(`Deleted subtitle file: ${subtitleFile}`);

        return subtitleData;
    } catch (error) {
        console.error('Error extracting subtitles:', error);
        throw error;
    }
}

function parseTimestamp(timestamp) {
    if (!timestamp) {
        console.warn('Empty timestamp encountered');
        return NaN;
    }

    const cleanTimestamp = timestamp.split(' ')[0];
    const parts = cleanTimestamp.split(':');
    if (parts.length !== 3) {
        console.warn(`Invalid timestamp format: ${timestamp}`);
        return NaN;
    }
    const hours = parseInt(parts[0], 10);
    const minutes = parseInt(parts[1], 10);
    const seconds = parseFloat(parts[2].replace(',', '.'));
    const totalSeconds = hours * 3600 + minutes * 60 + seconds;
    console.log(`Parsed timestamp "${cleanTimestamp}" to ${totalSeconds} seconds`);
    return totalSeconds;
}

module.exports = { extractVideoText };