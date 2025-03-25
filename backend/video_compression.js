const express = require('express');
const router = express.Router();
const multer = require('multer');
const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

// Configure multer for video upload
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = 'uploads/videos';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    cb(null, uuidv4() + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 500 * 1024 * 1024 // 500MB limit
  },
  fileFilter: (req, file, cb) => {
    // Log the file details for debugging
    console.log('Received file:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size
    });

    // Accept common video formats
    const allowedMimeTypes = [
      'video/mp4',
      'video/quicktime',
      'video/x-msvideo',
      'video/x-matroska',
      'video/webm',
      'video/3gpp',
      'video/x-ms-wmv',
      'video/x-flv',
      'video/x-m4v',
      'application/octet-stream' // Add this to handle cases where MIME type is not properly detected
    ];

    // Check file extension
    const allowedExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp', '.wmv', '.flv', '.m4v'];
    const fileExtension = path.extname(file.originalname).toLowerCase();

    // Accept if either MIME type or extension is valid
    if (allowedMimeTypes.includes(file.mimetype) || allowedExtensions.includes(fileExtension)) {
      cb(null, true);
    } else {
      console.error('Invalid file type:', file.mimetype, 'Extension:', fileExtension);
      cb(new Error(`Invalid file type: ${file.mimetype} (${fileExtension}). Only video files are allowed.`));
    }
  }
});

// Get video information
router.post('/info', upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      console.error('No file received in /info endpoint');
      return res.status(400).json({ error: 'No video file provided' });
    }

    console.log('Processing video info for file:', req.file.path);

    ffmpeg.ffprobe(req.file.path, (err, metadata) => {
      if (err) {
        console.error('Error getting video info:', err);
        // Clean up the file if there's an error
        try {
          fs.unlinkSync(req.file.path);
        } catch (unlinkErr) {
          console.error('Error deleting file:', unlinkErr);
        }
        return res.status(500).json({ error: 'Error processing video: ' + err.message });
      }

      const videoStream = metadata.streams.find(s => s.codec_type === 'video');
      const audioStream = metadata.streams.find(s => s.codec_type === 'audio');

      if (!videoStream) {
        console.error('No video stream found in file');
        return res.status(400).json({ error: 'No video stream found in file' });
      }

      res.json({
        duration: metadata.format.duration,
        size: metadata.format.size,
        bitrate: metadata.format.bit_rate,
        width: videoStream.width,
        height: videoStream.height,
        fps: eval(videoStream.r_frame_rate),
        audioBitrate: audioStream ? audioStream.bit_rate : null,
        format: metadata.format.format_name
      });
    });
  } catch (error) {
    console.error('Error in /info endpoint:', error);
    res.status(500).json({ error: 'Server error: ' + error.message });
  }
});

// Compress video
router.post('/compress', upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      console.error('No file received in /compress endpoint');
      return res.status(400).json({ error: 'No video file provided' });
    }

    console.log('Processing video compression for file:', {
      path: req.file.path,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    });

    // Verify file exists and is readable
    if (!fs.existsSync(req.file.path)) {
      console.error('File does not exist:', req.file.path);
      return res.status(400).json({ error: 'File does not exist' });
    }

    const {
      quality = 28,
      maxWidth = 1080, // Changed to 1080 for vertical video
      maxHeight = 1920, // Changed to 1920 for vertical video
      fps = 30,
      audioBitrate = 128
    } = req.body;

    // Convert parameters to numbers
    const parsedQuality = parseInt(quality, 10);
    const parsedMaxWidth = parseInt(maxWidth, 10);
    const parsedMaxHeight = parseInt(maxHeight, 10);
    const parsedFps = parseInt(fps, 10);
    const parsedAudioBitrate = parseInt(audioBitrate, 10);

    console.log('Compression parameters:', {
      quality: parsedQuality,
      maxWidth: parsedMaxWidth,
      maxHeight: parsedMaxHeight,
      fps: parsedFps,
      audioBitrate: parsedAudioBitrate
    });

    const outputPath = path.join('uploads/videos', `compressed_${uuidv4()}.mp4`);

    // First verify the video is valid using ffprobe
    ffmpeg.ffprobe(req.file.path, (err, metadata) => {
      if (err) {
        console.error('Error verifying video:', err);
        try {
          fs.unlinkSync(req.file.path);
        } catch (unlinkErr) {
          console.error('Error deleting file:', unlinkErr);
        }
        return res.status(400).json({ error: 'Invalid video file: ' + err.message });
      }

      const videoStream = metadata.streams.find(s => s.codec_type === 'video');
      if (!videoStream) {
        console.error('No video stream found');
        return res.status(400).json({ error: 'No video stream found' });
      }

      console.log('Video metadata:', {
        duration: metadata.format.duration,
        size: metadata.format.size,
        format: metadata.format.format_name,
        streams: metadata.streams.map(s => ({
          type: s.codec_type,
          codec: s.codec_name
        }))
      });

      // Calculate dimensions maintaining 9:16 aspect ratio
      const originalWidth = videoStream.width;
      const originalHeight = videoStream.height;
      const aspectRatio = originalWidth / originalHeight;

      let targetWidth = parsedMaxWidth;
      let targetHeight = parsedMaxHeight;

      // If video is wider than 9:16, scale down width
      if (aspectRatio > 9/16) {
        targetWidth = Math.round(parsedMaxHeight * (9/16));
      }
      // If video is taller than 9:16, scale down height
      else if (aspectRatio < 9/16) {
        targetHeight = Math.round(parsedMaxWidth * (16/9));
      }

      // Add padding if needed to maintain 9:16
      const padWidth = parsedMaxWidth - targetWidth;
      const padHeight = parsedMaxHeight - targetHeight;

      console.log('Target dimensions:', {
        targetWidth,
        targetHeight,
        padWidth,
        padHeight
      });

      // Proceed with compression
      let command = ffmpeg(req.file.path)
        .videoCodec('libx264')
        .addOptions([
          `-crf ${parsedQuality}`,
          '-preset medium',
          '-maxrate 2M',
          '-bufsize 4M',
          '-pix_fmt yuv420p', // Ensure compatibility
          '-movflags +faststart' // Enable fast start for web playback
        ]);

      // Add padding if needed
      if (padWidth > 0 || padHeight > 0) {
        command = command
          .size(`${parsedMaxWidth}x${parsedMaxHeight}`)
          .addOptions([
            `-vf "scale=${targetWidth}:${targetHeight}:force_original_aspect_ratio=decrease,pad=${parsedMaxWidth}:${parsedMaxHeight}:(ow-iw)/2:(oh-ih)/2"`
          ]);
      } else {
        command = command.size(`${targetWidth}x${targetHeight}`);
      }

      command
        .fps(parsedFps)
        .audioCodec('aac')
        .audioBitrate(`${parsedAudioBitrate}k`)
        .on('progress', (progress) => {
          console.log('Processing: ' + progress.percent + '% done');
        })
        .on('end', () => {
          console.log('Video compression completed successfully');
          // Clean up original file
          try {
            fs.unlinkSync(req.file.path);
          } catch (err) {
            console.error('Error deleting original file:', err);
          }
          
          // Send the compressed file
          res.download(outputPath, 'compressed_video.mp4', (err) => {
            if (err) {
              console.error('Error sending file:', err);
            }
            // Clean up compressed file after sending
            try {
              fs.unlinkSync(outputPath);
            } catch (unlinkErr) {
              console.error('Error deleting compressed file:', unlinkErr);
            }
          });
        })
        .on('error', (err) => {
          console.error('Error compressing video:', err);
          // Clean up files on error
          try {
            fs.unlinkSync(req.file.path);
            if (fs.existsSync(outputPath)) {
              fs.unlinkSync(outputPath);
            }
          } catch (unlinkErr) {
            console.error('Error cleaning up files:', unlinkErr);
          }
          res.status(500).json({ error: 'Error compressing video: ' + err.message });
        })
        .save(outputPath);
    });
  } catch (error) {
    console.error('Error in /compress endpoint:', error);
    res.status(500).json({ error: 'Server error: ' + error.message });
  }
});

module.exports = router; 