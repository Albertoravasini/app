# type: ignore
from openai import OpenAI
import sys
import json
import os
from dotenv import load_dotenv

# Carica le variabili d'ambiente dal file .env nella root del backend
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(backend_dir, '.env'))

def summarize_text(text):
    try:
        client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
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
        
        result = response.choices[0].message.content.strip()
        parts = result.split('Key Learning')
        summary = parts[0].replace('Summary:', '').strip()
        key_learning = parts[1].strip() if len(parts) > 1 else "No key learning extracted"
        
        return {
            "summary": summary,
            "key_learning": key_learning
        }
        
    except Exception as e:
        print(f"Errore durante la generazione del riassunto: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    try:
        input_text = sys.stdin.read()
        summary = summarize_text(input_text)
        if summary:
            print(json.dumps({"success": True, "summary": summary}))
        else:
            print(json.dumps({"success": False, "error": "Errore nella generazione del riassunto"}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)})) 