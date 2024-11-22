# type: ignore
import requests
import wikipediaapi
from duckduckgo_search import DDGS
from datetime import datetime
import json
import sys
from typing import List, Dict, Any
import asyncio
from bs4 import BeautifulSoup
import logging
from urllib.parse import urlparse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ContentFetcher:
    def __init__(self):
        logger.info("Inizializzazione ContentFetcher...")
        self.wiki = wikipediaapi.Wikipedia(
            language='en',
            extract_format=wikipediaapi.ExtractFormat.WIKI,
            user_agent='JustLearnApp/1.0 (albertoravasini@gmail.com)'
        )
        self.ddg = DDGS()
        logger.info("ContentFetcher inizializzato con successo")

    def _clean_query(self, query: str) -> str:
        """Pulisce e normalizza la query"""
        # Rimuovi caratteri speciali ma mantieni spazi e lettere
        cleaned = ''.join(char for char in query if char.isalnum() or char.isspace())
        # Normalizza spazi multipli
        cleaned = ' '.join(cleaned.split())
        return cleaned

    async def get_wiki_content(self, query: str) -> List[Dict[str, Any]]:
        """Ottiene contenuti da Wikipedia in inglese"""
        logger.info(f"Ricerca Wikipedia per: {query}")
        articles = []
        cleaned_query = self._clean_query(query)
        
        try:
            page = self.wiki.page(cleaned_query)
            if not page.exists():
                search_results = self.wiki.search(cleaned_query, results=3)
                for title in search_results:
                    page = self.wiki.page(title)
                    if page.exists():
                        image_url = ''
                        if page.images:
                            valid_images = [img for img in page.images 
                                          if any(ext in img.lower() for ext in ['.jpg', '.jpeg', '.png']) 
                                          and not 'icon' in img.lower()]
                            if valid_images:
                                image_url = valid_images[0]

                        articles.append({
                            'title': page.title,
                            'content': page.summary,
                            'imageUrl': image_url,
                            'date': datetime.now().strftime('%Y-%m-%d'),
                            'source': 'Wikipedia',
                            'url': page.fullurl,
                            'videoTitle': query
                        })
            else:
                image_url = ''
                if page.images:
                    valid_images = [img for img in page.images 
                                  if any(ext in img.lower() for ext in ['.jpg', '.jpeg', '.png'])
                                  and not 'icon' in img.lower()]
                    if valid_images:
                        image_url = valid_images[0]

                articles.append({
                    'title': page.title,
                    'content': page.summary,
                    'imageUrl': image_url,
                    'date': datetime.now().strftime('%Y-%m-%d'),
                    'source': 'Wikipedia',
                    'url': page.fullurl,
                    'videoTitle': query
                })
            
            logger.info(f"Trovati {len(articles)} articoli da Wikipedia")
            return articles
        except Exception as e:
            logger.error(f"Errore Wikipedia: {str(e)}")
            return []

    async def get_ddg_content(self, query: str) -> List[Dict[str, Any]]:
        """Ottiene contenuti da DuckDuckGo in inglese"""
        logger.info(f"Ricerca DuckDuckGo per: {query}")
        cleaned_query = self._clean_query(query)
        
        try:
            search_query = f"{cleaned_query} article"
            
            # Ricerca testuale
            text_results = self.ddg.text(
                search_query,
                region='wt-wt',
                safesearch='moderate',
                timelimit='m',
                max_results=4
            )
            
            # Ricerca immagini
            image_results = self.ddg.images(
                search_query,
                region='wt-wt',
                safesearch='moderate',
                size=None,
                color=None,
                type_image=None,
                layout=None,
                license_image=None,
                max_results=4
            )
            
            articles = []
            for i, result in enumerate(text_results):
                try:
                    # Estrai il dominio dall'URL come fonte usando urlparse
                    url = result.get('link', '')
                    parsed_url = urlparse(url)
                    domain = parsed_url.netloc
                    
                    # Gestisci diversi formati di dominio
                    if domain:
                        # Rimuovi www. e altri sottodomini
                        parts = domain.split('.')
                        if len(parts) >= 2:
                            if parts[0] == 'www':
                                source = parts[1].capitalize()
                            else:
                                source = parts[0].capitalize()
                        else:
                            source = domain.capitalize()
                    else:
                        source = result.get('source', 'Unknown Source')

                    # Mappa di sostituzioni per nomi di fonti comuni
                    source_mapping = {
                        'Medium': 'Medium',
                        'Github': 'GitHub',
                        'Stackoverflow': 'Stack Overflow',
                        'Guardian': 'The Guardian',
                        'Nytimes': 'The New York Times',
                        'Bbc': 'BBC',
                        'Cnn': 'CNN',
                        # Aggiungi altre mappature secondo necessità
                    }
                    
                    # Applica la mappatura se disponibile
                    source = source_mapping.get(source, source)

                    # Trova un'immagine corrispondente se disponibile
                    image_url = ''
                    if i < len(image_results):
                        image_url = image_results[i].get('image', '')

                    logger.info(f"Fonte estratta per {url}: {source}")  # Log per debug

                    articles.append({
                        'title': result.get('title', ''),
                        'content': result.get('body', ''),
                        'imageUrl': image_url,
                        'date': datetime.now().strftime('%Y-%m-%d'),
                        'source': source,
                        'url': url,
                        'videoTitle': query
                    })
                except Exception as e:
                    logger.error(f"Errore nell'elaborazione del risultato: {str(e)}")
                    continue

            logger.info(f"Trovati {len(articles)} risultati da varie fonti")
            return articles
            
        except Exception as e:
            logger.error(f"Errore nella ricerca: {str(e)}")
            return []

    async def get_all_content(self, query: str) -> List[Dict[str, Any]]:
        """Combina i risultati da tutte le fonti"""
        logger.info(f"Avvio ricerca contenuti per: {query}")
        
        # Esegui le ricerche in parallelo
        wiki_results, ddg_results = await asyncio.gather(
            self.get_wiki_content(query),
            self.get_ddg_content(query)
        )
        
        # Combina e deduplicizza i risultati
        all_results = wiki_results + ddg_results
        seen_titles = set()
        unique_results = []
        
        for result in all_results:
            if result['title'] and result['title'] not in seen_titles and result['content'].strip():
                seen_titles.add(result['title'])
                unique_results.append(result)
        
        logger.info(f"Trovati {len(unique_results)} risultati unici totali")
        return unique_results[:5]  # Limita a 5 risultati

def main():
    if len(sys.argv) > 1:
        query = ' '.join(sys.argv[1:])
        logger.info(f"Avvio ContentFetcher con query: {query}")
        
        try:
            fetcher = ContentFetcher()
            results = asyncio.run(fetcher.get_all_content(query))
            
            logger.info(f"Trovati {len(results)} risultati totali")
            print(json.dumps(results, ensure_ascii=False))
            
        except Exception as e:
            logger.error(f"Errore durante l'esecuzione: {str(e)}")
            print("[]")
    else:
        logger.error("Nessuna query fornita")
        print("[]")

if __name__ == "__main__":
    main() 