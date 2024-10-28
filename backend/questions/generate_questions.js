// generate_questions.js

const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const admin = require('firebase-admin');

// Helper function to convert SRT to plain text
// Helper function to convert SRT/VTT to plain text
function srtToText(subtitles) {
  return subtitles
    // Rimuovi l'header WEBVTT se presente
    .replace(/WEBVTT.*\n/g, '')
    // Rimuovi gli indici delle sottotitoli
    .replace(/^\d+\n/gm, '')
    // Rimuovi i timestamp (formato VTT e SRT)
    .replace(/\d{2}:\d{2}:\d{2}[.,]\d{3} --> \d{2}:\d{2}:\d{2}[.,]\d{3}\s*align:start position:\d+%?\n/g, '')
    // Rimuovi le linee di testo pulito (che non contengono tag)
    .replace(/^(?!.*<.*>).*\n/gm, '')
    // Rimuovi i timestamp inline come <00:00:00.199>
    .replace(/<\d{2}:\d{2}:\d{2}[.,]\d{3}>/g, '')
    // Rimuovi i tag <c> e </c>
    .replace(/<\/?c>/g, '')
    // Rimuovi qualsiasi altro tag HTML residuale
    .replace(/<\/?[^>]+(>|$)/g, '')
    // Sostituisci spazi multipli con uno singolo
    .replace(/\s+/g, ' ')
    .trim();
}

// Function to extract transcription using yt-dlp
function getVideoTranscript(videoUrl) {
  return new Promise((resolve, reject) => {
    // Extract video ID from the URL
    const videoIdMatch = videoUrl.match(/(?:v=|\/)([0-9A-Za-z_-]{11}).*/);
    const videoId = videoIdMatch ? videoIdMatch[1] : null;

    if (!videoId) {
      console.error('Invalid video URL format.');
      return reject(new Error('Invalid video URL.'));
    }

    // Definisci il percorso completo per i sottotitoli
    const subtitlePath = path.join(__dirname, `${videoId}.en.vtt`);

    // Definisci il percorso completo di output per yt-dlp
    const outputPath = path.join(__dirname, `${videoId}.%(ext)s`);

    // Definisci il percorso dell'interprete Python nell'ambiente virtuale
    const pythonInterpreter = path.join(__dirname, 'venv', 'bin', 'python3'); // Su Windows: 'venv\\Scripts\\python.exe'

    // Definisci il comando yt-dlp con il percorso di output corretto
    const ytDlpCommand = `yt-dlp --write-auto-sub --skip-download --sub-lang en "${videoUrl}" -o "${outputPath}"`;

    console.log(`Executing yt-dlp command: ${ytDlpCommand}`);

    exec(ytDlpCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`yt-dlp encountered an error: ${stderr}`);
        return reject(error);
      }

      console.log('yt-dlp command executed successfully.');
      console.log(`Looking for subtitle file at: ${subtitlePath}`);

      // Check if the subtitle file exists
      fs.access(subtitlePath, fs.constants.F_OK, (err) => {
        if (err) {
          console.error('Subtitle file does not exist.');
          return reject(new Error('Subtitle file not found.'));
        }

        // Read the subtitle file
        fs.readFile(subtitlePath, 'utf8', (err, data) => {
          if (err) {
            console.error('Error reading subtitle file:', err);
            return reject(err);
          }

          console.log('Subtitle file read successfully.');
          // Optionally, delete the subtitle file after reading
          fs.unlink(subtitlePath, (unlinkErr) => {
            if (unlinkErr) {
              console.error('Error deleting subtitle file:', unlinkErr);
            } else {
              console.log('Subtitle file deleted.');
            }
          });

          // Convert SRT to plain text
          const transcript = srtToText(data);
          resolve(transcript);
        });
      });
    });
  });
}

// Function to generate questions using GPT4All
function generateQuestions(transcript) {
  return new Promise((resolve, reject) => {
    // Create a prompt for GPT4All
    const prompt = `
Transcript:
${transcript}
`;

    // Paths for input and output files
    const inputPath = path.join(__dirname, 'gpt_input.txt');
    const outputPath = path.join(__dirname, 'gpt_output.json');

    console.log('Writing prompt to input file.');
    // Write the prompt to the input file
    fs.writeFileSync(inputPath, prompt, 'utf8');

    // Definisci il percorso dell'interprete Python nell'ambiente virtuale
    const pythonInterpreter = path.join(__dirname, 'venv', 'bin', 'python3'); // Su Windows: 'venv\\Scripts\\python.exe'

    // Execute the Python script con python3
    // Execute the Python script con python3
    const pythonCommand = `"${pythonInterpreter}" "${path.join(__dirname, 'generate_questions.py')}" "${inputPath}" "${outputPath}"`;
    console.log(`Executing Python script: ${pythonCommand}`);

    exec(pythonCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`GPT4All encountered an error: ${stderr}`);
        console.error(`Standard Output: ${stdout}`);
        return reject(error);
      }

      console.log('GPT4All script executed successfully.');
      console.log(`Looking for output file at: ${outputPath}`);

      // Check if the output file exists
      fs.access(outputPath, fs.constants.F_OK, (err) => {
        if (err) {
          console.error('GPT4All output file does not exist.');
          return reject(new Error('GPT4All output file not found.'));
        }

        // Read the output JSON file
        fs.readFile(outputPath, 'utf8', (err, data) => {
          if (err) {
            console.error('Error reading GPT4All output file:', err);
            return reject(err);
          }

          console.log('GPT4All output file read successfully.');
          // Optionally, delete the output file after reading
          fs.unlink(outputPath, (unlinkErr) => {
            if (unlinkErr) {
              console.error('Error deleting GPT4All output file:', unlinkErr);
            } else {
              console.log('GPT4All output file deleted.');
            }
          });

          try {
            const questions = JSON.parse(data);
            console.log('Questions parsed successfully.');
            resolve(questions);
          } catch (parseError) {
            console.error('Error parsing GPT4All output:', parseError);
            reject(parseError);
          }
        });
      });
    });
  });
}

// Definisci l'endpoint /generate_questions
router.post('/', async (req, res) => {
  const { videoUrl } = req.body;

  if (!videoUrl) {
    console.error('No video URL provided in the request.');
    return res.status(400).json({ error: 'Video URL is required.' });
  }

  try {
    console.log(`Received request to generate questions for video URL: ${videoUrl}`);

    // Step 1: Extract transcription using yt-dlp
    const transcript = await getVideoTranscript(videoUrl);

    if (!transcript) {
      console.error('Transcript extraction failed.');
      return res.status(500).json({ error: 'Unable to extract transcript from the video.' });
    }

    console.log('Transcript extracted successfully.');

    // Step 2: Generate questions using GPT4All
    const questions = await generateQuestions(transcript);

    if (!questions || questions.length === 0) {
      console.error('Question generation failed.');
      return res.status(500).json({ error: 'Failed to generate questions.' });
    }

    console.log('Questions generated successfully.');

    // Step 3: Send questions back to the client
    return res.json({ questions });
  } catch (error) {
    console.error('Error in /generate_questions:', error);
    return res.status(500).json({ error: 'Internal server error.' });
  }
});

module.exports = router;