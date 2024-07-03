const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const extractVideoText = (videoUrl) => {
  return new Promise((resolve, reject) => {
    const outputDir = path.resolve(__dirname, '../subtitles');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }
    const outputFileName = `${uuidv4()}.en.vtt`;
    const outputFilePath = path.resolve(outputDir, outputFileName);
    const command = `yt-dlp --write-auto-sub --sub-lang en --sub-format vtt --skip-download -o "${outputFilePath}" ${videoUrl}`;
    console.log(`Executing command: ${command}`);
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error.message}`);
        return reject(error);
      }
      if (stderr) {
        console.error(`Stderr: ${stderr}`);
        if (stderr.includes('WARNING: Unable to download video subtitles')) {
          return reject(new Error('Subtitle download error'));
        }
      }
      const finalOutputFilePath = `${outputFilePath}.en.vtt`;
      console.log(`Output file path: ${finalOutputFilePath}`);
      fs.access(finalOutputFilePath, fs.constants.F_OK, (err) => {
        if (err) {
          console.error(`File not found: ${finalOutputFilePath}`);
          return reject(new Error('Subtitle file not found'));
        }
        fs.readFile(finalOutputFilePath, 'utf8', (err, data) => {
          if (err) {
            console.error(`Read file error: ${err}`);
            return reject(err);
          }
          const text = data.replace(/(\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3})/g, '')
                           .replace(/<\/?[^>]+(>|$)/g, '')
                           .replace(/\n+/g, ' ')
                           .replace(/\s{2,}/g, ' ')
                           .replace(/align:start position:0%/g, '')
                           .replace(/(\[\w+\])/g, '')
                           .replace(/(.+?)(\s+\1)+/g, '$1')
                           .trim();
          fs.unlink(finalOutputFilePath, (err) => {
            if (err) console.error(`Error deleting file: ${err}`);
          });
          resolve(text);
        });
      });
    });
  });
};

module.exports = {
  extractVideoText
};