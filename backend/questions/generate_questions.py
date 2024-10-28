# generate_questions.py

import sys
import json
from gpt4all import GPT4All
import tiktoken
import re
import traceback

def count_tokens(text, encoding_name='gpt2'):
    """Counts the number of tokens in the text using the specified encoding."""
    encoding = tiktoken.get_encoding(encoding_name)
    tokens = encoding.encode(text)
    return len(tokens)

def split_text_into_chunks(text, max_tokens=2000, encoding_name='gpt2'):
    """Splits the text into chunks that do not exceed max_tokens."""
    encoding = tiktoken.get_encoding(encoding_name)
    tokens = encoding.encode(text)
    
    chunks = []
    for i in range(0, len(tokens), max_tokens):
        chunk_tokens = tokens[i:i+max_tokens]
        chunk_text = encoding.decode(chunk_tokens)
        chunks.append(chunk_text)
    
    return chunks

def generate_questions_for_chunk(model, chunk):
    """Generates questions for a single chunk of text."""
    prompt = f"""
You are an expert educator. Generate five multiple-choice questions based on the following transcript. Each question should:

- Be clear and concise.
- Have four options labeled A), B), C), and D).
- Have only one correct answer.
- Include a brief explanation for the correct answer.

Format:

Question 1: [Question text]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]
Correct answer: [A/B/C/D]
Explanation: [Explanation text]

(Repeat for questions 2 to 5)

Do not include any additional text besides the questions, options, correct answers, and explanations.

Transcript:
{chunk}
"""
    response = model.generate(prompt, max_tokens=1500)
    print("Model response:\n", response)

    # Remove any leading/trailing whitespace
    response = response.strip()

    # Apply the regex pattern to the entire response
    pattern = re.compile(
        r"Question\s*\d+:\s*(?P<question>.*?)\n"
        r"A\)\s*(?P<option_a>.*?)\n"
        r"B\)\s*(?P<option_b>.*?)\n"
        r"C\)\s*(?P<option_c>.*?)\n"
        r"D\)\s*(?P<option_d>.*?)\n"
        r"Correct answer:\s*(?P<correct_answer>[ABCD])\)?\n"
        r"Explanation:\s*(?P<explanation>.*?)(?=\nQuestion\s*\d+:|\Z)",
        re.DOTALL
    )

    matches = pattern.finditer(response)
    questions = []
    for match in matches:
        question_text = match.group('question').strip()
        choices = [
            match.group('option_a').strip(),
            match.group('option_b').strip(),
            match.group('option_c').strip(),
            match.group('option_d').strip()
        ]
        correct_answer_letter = match.group('correct_answer').strip()
        explanation = match.group('explanation').strip()

        # Map letter to index
        letter_to_index = {'A': 0, 'B': 1, 'C': 2, 'D': 3}
        correct_answer_index = letter_to_index.get(correct_answer_letter, None)

        if correct_answer_index is not None and correct_answer_index < len(choices):
            correct_answer_text = choices[correct_answer_index]
        else:
            correct_answer_text = ""  # Default if something goes wrong

        questions.append({
            'question': question_text,
            'choices': choices,
            'correct_answer': correct_answer_text,
            'explanation': explanation
        })
    return questions

def main(input_file, output_file):
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            transcript = f.read()
    except FileNotFoundError:
        print(f"Input file {input_file} not found.")
        sys.exit(1)

    # Count tokens in the transcript
    total_tokens = count_tokens(transcript)
    print(f"Total tokens in transcript: {total_tokens}")

    # Split transcript into chunks if necessary
    if total_tokens <= 2048:
        chunks = [transcript]
    else:
        # Split the transcript into chunks of 2000 tokens to avoid exceeding the limit
        chunks = split_text_into_chunks(transcript, max_tokens=2000)
        print(f"Transcript split into {len(chunks)} chunks.")

    try:
        # Initialize GPT4All model
        model = GPT4All("Meta-Llama-3-8B-Instruct.Q4_0.gguf")  # Replace with your model name
    except Exception as e:
        print(f"Error initializing GPT4All model: {e}")
        sys.exit(1)

    all_questions = []

    for idx, chunk in enumerate(chunks):
        print(f"Generating questions for chunk {idx + 1}/{len(chunks)}...")
        questions = generate_questions_for_chunk(model, chunk)
        all_questions.extend(questions)

    if not all_questions:
        print("No questions were generated.")
        sys.exit(1)

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_questions, f, indent=2)
    except Exception as e:
        print(f"Error writing to output file: {e}")
        sys.exit(1)

    print(f"Questions generated and saved to {output_file}.")

if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            print("Usage: python generate_questions.py <input_file> <output_file>")
            sys.exit(1)

        input_file = sys.argv[1]
        output_file = sys.argv[2]

        main(input_file, output_file)
    except Exception as e:
        print(f"An error occurred: {e}")
        traceback.print_exc()
        sys.exit(1)