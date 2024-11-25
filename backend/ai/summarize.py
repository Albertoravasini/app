# type: ignore
from openai import OpenAI
import sys
import json
import os
import logging
from dotenv import load_dotenv

# Configura logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carica le variabili d'ambiente
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(backend_dir, '.env'))

def summarize_text(text):
    try:
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            logger.error("API key non trovata nel file .env")
            return {
                "success": False,
                "error": "API key non configurata"
            }
            
        logger.info("Inizializzazione client OpenAI...")
        client = OpenAI(api_key=api_key)
        
        logger.info("Invio richiesta a OpenAI...")
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{
                "role": "system",
                "content": "Sei un assistente che crea riassunti concisi e punti chiave."
            }, {
                "role": "user",
                "content": f"""Please provide:
                1. A concise summary of the following text in English (2-3 sentences)
                2. Three key learnings from this text, formatted as bullet points

                Text:
                {text[:2000]}"""
            }],
            temperature=0.7,
            max_tokens=500
        )
        
        logger.info("Elaborazione risposta...")
        result = response.choices[0].message.content.strip()
        parts = result.split('Key Learning')
        summary = parts[0].replace('Summary:', '').strip()
        key_learning = parts[1].strip() if len(parts) > 1 else "No key learning extracted"
        
        return {
            "success": True,
            "summary": {
                "summary": summary,
                "key_learning": key_learning
            }
        }
        
    except Exception as e:
        logger.error(f"Errore dettagliato: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }

if __name__ == "__main__":
    try:
        logger.info("Lettura input...")
        input_text = sys.stdin.read()
        if not input_text:
            logger.error("Nessun testo ricevuto in input")
            print(json.dumps({
                "success": False,
                "error": "Nessun testo fornito"
            }))
        else:
            logger.info("Generazione riassunto...")
            result = summarize_text(input_text)
            print(json.dumps(result))
    except Exception as e:
        logger.error(f"Errore principale: {str(e)}")
        print(json.dumps({
            "success": False,
            "error": str(e)
        })) 