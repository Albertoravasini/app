const express = require('express');
const router = express.Router();
const { spawn } = require('child_process');
const path = require('path');

// Aggiungi gestione errori centralizzata
const handlePythonError = (error, res) => {
  console.error('Python error:', error);
  res.status(500).json({
    success: false,
    message: 'Errore nel processo Python',
    error: error
  });
};

// Aggiungi timeout per il processo Python
const PYTHON_TIMEOUT = 30000; // 30 secondi

router.get('/chat', (req, res) => {
  res.status(200).json({ 
    success: true, 
    message: 'Server AI chat disponibile' 
  });
});

router.post('/chat', async (req, res) => {
  const { message, videoId, levelId, chatHistory, videoTitle } = req.body;
  
  try {
    const pythonProcess = spawn('/root/app/backend/venv/bin/python3', [
      path.join(__dirname, 'ai', 'chat.py')
    ]);

    let outputData = '';
    let errorData = '';

    // Aggiungi timeout
    const timeoutId = setTimeout(() => {
      pythonProcess.kill();
      handlePythonError('Timeout exceeded', res);
    }, PYTHON_TIMEOUT);

    pythonProcess.stdin.write(JSON.stringify({
      message,
      chatHistory,
      videoTitle
    }));
    pythonProcess.stdin.end();

    pythonProcess.stdout.on('data', (data) => {
      outputData += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      errorData += data.toString();
    });

    pythonProcess.on('close', (code) => {
      clearTimeout(timeoutId);
      
      if (code !== 0) {
        return handlePythonError(errorData, res);
      }

      try {
        const result = JSON.parse(outputData);
        res.json({
          success: true,
          response: result.response || result.message
        });
      } catch (error) {
        handlePythonError('Errore nel parsing della risposta', res);
      }
    });
  } catch (error) {
    handlePythonError(error.message, res);
  }
});

module.exports = router; 