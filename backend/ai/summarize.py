# type: ignore
from gpt4all import GPT4All
import sys
import json

def summarize_text(text):
    try:
        model = GPT4All("ai/models/mistral-7b-instruct.gguf")
        
        prompt = f"""
        Please provide:
        1. A concise summary of the following text in English (2-3 sentences)
        2. Three key learnings from this text, formatted as bullet points

        Text:
        {text[:2000]}
        
        Format your response as:
        Summary: [your summary here]
        Key Learning:
        • [first key learning]
        • [second key learning]
        • [third key learning]
        """
        
        response = model.generate(prompt, max_tokens=500)
        
        # Parsing della risposta per separare il riassunto e l'apprendimento chiave
        parts = response.strip().split('Key Learning:')
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