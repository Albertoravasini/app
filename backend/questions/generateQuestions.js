const axios = require('axios');
const natural = require('natural');
const { retryWithDelay } = require('./utils');
const WordNet = require('node-wordnet');
const wordnet = new WordNet();

const changeNumbers = (text) => {
  return text.replace(/\d+/g, (match) => {
    const num = parseInt(match);
    const delta = Math.floor(Math.random() * 10) + 1; // Cambia il numero di un valore compreso tra 1 e 10
    const newNum = Math.random() > 0.5 ? num + delta : num - delta;
    return newNum.toString();
  });
};

const generatePlausibleIncorrectChoices = async (correctAnswer) => {
  const incorrectChoices = [];
  const tokenizer = new natural.WordTokenizer();
  let hasAddedNotVariant = false;

  for (let i = 0; i < 3; i++) {
    let incorrectChoice = correctAnswer;

    // Gestione del caso "not"
    if (correctAnswer.includes('not') && !hasAddedNotVariant) {
      incorrectChoice = correctAnswer.replace(' not', '');
      incorrectChoices.push(incorrectChoice);
      hasAddedNotVariant = true;
      continue;
    }

    // Gestione dei numeri
    if (/\d/.test(correctAnswer)) {
      incorrectChoice = changeNumbers(correctAnswer);
      incorrectChoices.push(incorrectChoice);
      continue;
    }

    // Tokenizza la risposta corretta
    const tokens = tokenizer.tokenize(correctAnswer);

    // Seleziona una parola da perturbare
    const perturbIndex = Math.floor(Math.random() * tokens.length);
    const word = tokens[perturbIndex];

    // Ottieni sinonimi usando WordNet
    try {
      const synonyms = await new Promise((resolve, reject) => {
        wordnet.lookup(word, (results) => {
          if (results.length === 0) {
            reject(new Error('No synonyms found'));
          } else {
            resolve(results.flatMap(result => result.synonyms));
          }
        });
      });

      if (synonyms.length > 0) {
        const synonym = synonyms[Math.floor(Math.random() * synonyms.length)];
        tokens[perturbIndex] = synonym;
      } else {
        // Semplice fallback perturbation: mescola i caratteri della parola
        tokens[perturbIndex] = word.split('').sort(() => Math.random() - 0.5).join('');
      }

      incorrectChoice = tokens.join(' ');
      incorrectChoices.push(incorrectChoice);

    } catch (error) {
      console.error('Error fetching synonyms:', error.message);
    }
  }

  return incorrectChoices;
};

const generateQuestionAndAnswer = async (text) => {
  try {
    console.log('Generating summary for text:', text);

    const maxTextLength = 1024;
    const truncatedText = text.length > maxTextLength ? text.slice(0, maxTextLength) : text;

    const summaryResponse = await retryWithDelay(() => axios.post('https://api-inference.huggingface.co/models/facebook/bart-large-cnn', {
      inputs: truncatedText,
      parameters: { max_length: 150 }
    }, {
      headers: { 'Authorization': `Bearer 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` }
    }), 5, 5000);

    console.log('Summary response:', summaryResponse.data);
    if (summaryResponse.status !== 200) {
      console.error('Error generating summary:', summaryResponse.status, summaryResponse.data);
      throw new Error('Error generating summary');
    }

    const summary = summaryResponse.data[0]?.summary_text ?? '';

    console.log('Generating question and answer for summary:', summary);

    const questionResponse = await retryWithDelay(() => axios.post('https://api-inference.huggingface.co/models/iarfmoose/t5-base-question-generator', {
      inputs: summary,
    }, {
      headers: { 'Authorization': `Bearer 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` }
    }), 5, 5000);

    if (questionResponse.status !== 200) {
      console.error('Error generating question:', questionResponse.status, questionResponse.data);
      throw new Error('Error generating question');
    }

    const generatedQuestion = questionResponse.data[0]?.generated_text ?? 'Default question if none generated';

    const answerResponse = await retryWithDelay(() => axios.post('https://api-inference.huggingface.co/models/deepset/roberta-base-squad2', {
      inputs: {
        question: generatedQuestion,
        context: summary
      }
    }, {
      headers: { 'Authorization': `Bearer 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` }
    }), 5, 5000);

    if (answerResponse.status !== 200) {
      console.error('Error generating answer:', answerResponse.status, answerResponse.data);
      throw new Error('Error generating answer');
    }

    const correctAnswer = answerResponse.data?.answer ?? 'Default answer if none generated';

    const incorrectChoices = await generatePlausibleIncorrectChoices(correctAnswer);

    const choices = [
      correctAnswer,
      ...incorrectChoices
    ].sort(() => Math.random() - 0.5);

    return {
      question: generatedQuestion,
      choices,
      correctAnswer: correctAnswer
    };
  } catch (error) {
    if (error.response) {
      console.error('API Response Error:', error.response.data);
    } else {
      console.error('Error in generateQuestionAndAnswer:', error.message);
    }
    throw error;
  }
};

module.exports ={
  generateQuestionAndAnswer
};