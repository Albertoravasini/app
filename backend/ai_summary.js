const express = require('express');
const router = express.Router();
const { spawn } = require('child_process');
const path = require('path');

// Determina il percorso Python in base all'ambiente
const isProd = process.env.NODE_ENV === 'production';
const PYTHON_PATH = isProd ? '/root/app/backend/venv/bin/python3' : 'python3';

router.post('/summarize', async (req, res) => {
  const { content } = req.body;
  let hasResponded = false;
  
  if (!content) {
    return res.status(400).json({ 
      success: false, 
      message: 'Il contenuto è richiesto' 
    });
  }

  try {
    const pythonProcess = spawn(PYTHON_PATH, [
      path.join(__dirname, 'ai', 'summarize.py')
    ]);

    let outputData = '';
    let errorData = '';

    pythonProcess.stdout.on('data', (data) => {
      outputData += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      errorData += data.toString();
    });

    pythonProcess.stdin.write(content);
    pythonProcess.stdin.end();

    pythonProcess.on('close', (code) => {
      if (code !== 0) {
        console.error('Errore nel processo Python:', errorData);
        return res.status(500).json({ 
          success: false, 
          message: 'Errore nella generazione del riassunto' 
        });
      }

      try {
        const result = JSON.parse(outputData);
        res.json(result);
      } catch (error) {
        console.error('Errore nel parsing del risultato:', error);
        res.status(500).json({ 
          success: false, 
          message: 'Errore nel parsing del risultato' 
        });
      }
    });

  } catch (error) {
    console.error('Errore nella generazione del riassunto:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Errore nella generazione del riassunto',
      error: error.message 
    });
  }
});

module.exports = router; 