const express = require('express');
const router = express.Router();
const { spawn } = require('child_process');
const path = require('path');

// Aumenta il timeout a 5 minuti
const PYTHON_TIMEOUT = 300000; // 5 minuti in millisecondi

// Modifica la gestione degli errori per evitare risposte multiple
const handlePythonError = (error, res) => {
  if (!res.headersSent) {
    console.error('Python error:', error);
    res.status(500).json({
      success: false,
      message: 'Errore nel processo Python',
      error: error
    });
  }
};

router.get('/chat', (req, res) => {
  res.status(200).json({ 
    success: true, 
    message: 'Server AI chat disponibile' 
  });
});

router.post('/chat', async (req, res) => {
  const { message, videoId, levelId, chatHistory, videoTitle } = req.body;
  let hasResponded = false;
  
  try {
    const pythonProcess = spawn('/root/app/backend/venv/bin/python3', [
      path.join(__dirname, 'ai', 'chat.py')
    ]);

    let outputData = '';
    let errorData = '';

    const timeoutId = setTimeout(() => {
      if (!hasResponded) {
        hasResponded = true;
        pythonProcess.kill();
        handlePythonError('Timeout exceeded - Model download in progress', res);
      }
    }, PYTHON_TIMEOUT);

    pythonProcess.stdout.on('data', (data) => {
      outputData += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      errorData += data.toString();
    });

    pythonProcess.on('close', (code) => {
      clearTimeout(timeoutId);
      
      if (!hasResponded) {
        hasResponded = true;
        if (code !== 0) {
          handlePythonError(errorData, res);
        } else {
          try {
            const result = JSON.parse(outputData);
            res.json({
              success: true,
              response: result.response || result.message
            });
          } catch (error) {
            handlePythonError('Errore nel parsing della risposta', res);
          }
        }
      }
    });

    pythonProcess.stdin.write(JSON.stringify({
      message,
      chatHistory,
      videoTitle
    }));
    pythonProcess.stdin.end();

  } catch (error) {
    if (!hasResponded) {
      hasResponded = true;
      handlePythonError(error.message, res);
    }
  }
});

module.exports = router; 