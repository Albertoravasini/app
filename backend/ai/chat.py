# type: ignore
from openai import OpenAI
import sys
import json
import os
from typing import Dict, List
import logging
from dotenv import load_dotenv

# Carica le variabili d'ambiente dal file .env nella root del backend
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(backend_dir, '.env'))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AIChat:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
    def generate_response(self, message: str, chat_history: List[Dict], video_title: str = "") -> Dict:
        try:
            messages = self._build_messages(message, chat_history, video_title)
            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=messages,
                temperature=0.7,
                max_tokens=200
            )
            
            return {
                "success": True,
                "response": response.choices[0].message.content.strip()
            }
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }

    def _build_messages(self, message: str, chat_history: List[Dict], video_title: str) -> List[Dict]:
        messages = [{
            "role": "system",
            "content": f"""Sei un tutor che aiuta gli studenti a comprendere meglio i video educativi.
            Stai rispondendo a domande sul video: "{video_title}"
            Rispondi in modo BREVE e CONCISO (massimo 2-3 frasi).
            
            Regole:
            1. Usa le informazioni dalle chat precedenti
            2. Rispondi SOLO alla domanda specifica
            3. Non ripetere informazioni già date
            4. Mantieni un tono amichevole ma professionale"""
        }]
        
        # Aggiungi la cronologia della chat
        for msg in chat_history:
            role = "assistant" if msg.get('isAi') else "user"
            messages.append({
                "role": role,
                "content": msg.get('content', '')
            })
        
        # Aggiungi il messaggio corrente
        messages.append({
            "role": "user",
            "content": message
        })
        
        return messages

def main():
    try:
        input_data = json.loads(sys.stdin.read())
        ai_chat = AIChat()
        result = ai_chat.generate_response(
            input_data.get("message", ""),
            input_data.get("chatHistory", []),
            input_data.get("videoTitle", "")
        )
        print(json.dumps(result))
    except Exception as e:
        logger.error(f"Main error: {str(e)}")
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))

if __name__ == "__main__":
    main() 