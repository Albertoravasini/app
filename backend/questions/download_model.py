# download_model.py

from gpt4all import GPT4All

def download_model():
    # Specifica il nome del modello che desideri scaricare
    model = GPT4All("Meta-Llama-3-8B-Instruct.Q4_0.gguf")  # Puoi sostituire con il modello desiderato
    model.generate("Verifica il download del modello.")  # Questo comando forzerà il download del modello

if __name__ == "__main__":
    download_model()