# type: ignore
from gpt4all import GPT4All
import sys
import json
from typing import Dict, List, Optional
import logging

# Configura logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AIChat:
    def __init__(self, model_path: str = "ai/models/mistral-7b-instruct.gguf"):
        self.model = GPT4All(model_path)
        
    def generate_response(self, message: str, chat_history: List[Dict], video_title: str = "") -> Dict:
        try:
            context = self._build_context(message, chat_history, video_title)
            response = self.model.generate(
                context,
                max_tokens=200,
                temp=0.7,
                top_k=40,
                top_p=0.4,
                repeat_penalty=1.18
            )
            
            return {
                "success": True,
                "response": response.strip()
            }
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }

    def _build_context(self, message: str, chat_history: List[Dict], video_title: str) -> str:
        return f"""
        Sei un tutor che aiuta gli studenti a comprendere meglio i video educativi.
        Stai rispondendo a domande sul video: "{video_title}"
        Rispondi in modo BREVE e CONCISO (massimo 2-3 frasi).
        
        Regole:
        1. Usa le informazioni dalle chat precedenti
        2. Rispondi SOLO alla domanda specifica
        3. Non ripetere informazioni già date
        4. Mantieni un tono amichevole ma professionale
        
        Cronologia della chat:
        {self._format_chat_history(chat_history)}
        
        Domanda dello studente:
        {message}
        """

    @staticmethod
    def _format_chat_history(chat_history: List[Dict]) -> str:
        if not chat_history:
            return "Nessuna cronologia precedente."
        
        return "\n".join(
            f"{'Studente' if not msg.get('isAi') else 'Insegnante'}: {msg.get('content', '')}"
            for msg in chat_history
        )

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