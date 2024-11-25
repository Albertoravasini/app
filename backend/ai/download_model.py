# type: ignore
from gpt4all import GPT4All
import os
import sys

def download_model():
    MODEL_PATH = "/root/app/backend/ai/models"
    MODEL_NAME = "Meta-Llama-3-8B-Instruct.Q4_0.gguf"
    
    try:
        os.makedirs(MODEL_PATH, exist_ok=True)
        
        print(f"Inizializzazione download del modello in {MODEL_PATH}...")
        model = GPT4All(MODEL_NAME, model_path=MODEL_PATH, device='cpu')
        print("Download completato con successo!")
        return True
    except Exception as e:
        print(f"Errore durante il download: {str(e)}")
        return False

if __name__ == "__main__":
    download_model() 