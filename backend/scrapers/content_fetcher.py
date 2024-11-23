# backend/scrapers/content_fetcher.py
# type: ignore
import os
import requests
from datetime import datetime
import json
import sys
from typing import List, Dict, Any, Tuple
import asyncio
from bs4 import BeautifulSoup
import logging
from urllib.parse import urlparse
import aiohttp
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# Gestione importazioni con try/except
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError as e:
    logging.error(f"Errore nell'importazione dei moduli: {e}")
    logging.error("Esegui: pip3 install python-dotenv google-api-python-client google-auth-httplib2 google-auth-oauthlib")
    raise

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ContentFetcher:
    def __init__(self):
        logger.info("Inizializzazione ContentFetcher...")
        self.google_api_key = os.getenv('GOOGLE_API_KEY')
        self.google_cse_id = os.getenv('GOOGLE_CSE_ID')
        
        if not self.google_api_key or not self.google_cse_id:
            raise ValueError("Chiavi API mancanti")
        
        logger.info(f"CSE ID configurato: {self.google_cse_id}")
        logger.info(f"API Key configurata: {self.google_api_key[:5]}...")
        
        # Inizializza il servizio una volta sola
        self.service = build(
            "customsearch", 
            "v1",
            developerKey=self.google_api_key,
            cache_discovery=False
        )

    def _clean_query(self, query: str) -> str:
        """Pulisce e normalizza la query"""
        cleaned = ''.join(char for char in query if char.isalnum() or char.isspace())
        cleaned = ' '.join(cleaned.split())
        return cleaned

    async def fetch_full_content(self, url: str) -> Tuple[str, str]:
        """Recupera sia il riassunto che il contenuto completo dall'URL"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml',
                'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7'
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.get(url, headers=headers, timeout=10) as response:
                    if response.status != 200:
                        return '', ''
                    
                    html = await response.text()
                    soup = BeautifulSoup(html, 'html.parser')
                    
                    # Rimuovi elementi non necessari
                    for tag in soup(['script', 'style', 'nav', 'header', 'footer', 'aside']):
                        tag.decompose()
                    
                    # Cerca il contenuto principale
                    main_content = None
                    for selector in ['article', '.article', '.post-content', '.entry-content', 'main']:
                        main_content = soup.select_one(selector)
                        if main_content:
                            break
                    
                    if main_content:
                        text = ' '.join(main_content.stripped_strings)
                    else:
                        text = ' '.join(soup.body.stripped_strings)
                    
                    # Pulisci il testo
                    text = ' '.join(text.split())
                    
                    # Crea un riassunto (primi 200 caratteri)
                    summary = text[:200] + "..." if len(text) > 200 else text
                    
                    return summary, text[:5000]  # Riassunto e contenuto completo (limitato a 5000 caratteri)
                
        except Exception as e:
            logger.error(f"Errore nel recupero del contenuto da {url}: {str(e)}")
            return '', ''

    async def get_google_search_content(self, query: str) -> List[Dict[str, Any]]:
        """Usa Google Custom Search API per ottenere articoli"""
        logger.info(f"Google Custom Search per: {query}")
        
        try:
            result = self.service.cse().list(
                q=query,
                cx=self.google_cse_id,
                num=10,
                dateRestrict='y1',
                safe='active'
            ).execute()
            
            articles = []
            for item in result['items']:
                # Default alla data corrente solo se necessario
                article_date = datetime.now().strftime('%d/%m/%Y')
                
                try:
                    if 'pagemap' in item and 'metatags' in item['pagemap']:
                        metatags = item['pagemap']['metatags'][0]
                        
                        # Lista di possibili campi data
                        date_fields = [
                            'article:published_time',
                            'datePublished',
                            'og:article:published_time',
                            'date',
                            'pubdate'
                        ]
                        
                        for field in date_fields:
                            if field in metatags and metatags[field]:
                                date_str = metatags[field]
                                # Rimuovi la parte dell'orario se presente
                                if 'T' in date_str:
                                    date_str = date_str.split('T')[0]
                                try:
                                    # Prova a parsare la data
                                    parsed_date = datetime.strptime(date_str, '%Y-%m-%d')
                                    article_date = parsed_date.strftime('%d/%m/%Y')
                                    logger.info(f"Data estratta per {item.get('title')}: {article_date}")
                                    break
                                except ValueError:
                                    continue
                except Exception as e:
                    logger.error(f"Errore nell'estrazione della data: {e}")
                
                summary, full_content = await self.fetch_full_content(item['link'])
                
                article = {
                    'title': item.get('title', ''),
                    'content': summary or item.get('snippet', ''),
                    'full_content': full_content,
                    'url': item.get('link', ''),
                    'source': urlparse(item.get('link', '')).netloc,
                    'date': article_date,  # Usa la data estratta
                    'imageUrl': self._extract_image_url(item)
                }
                
                articles.append(article)
                logger.info(f"Articolo elaborato: {article['title']} - Data: {article_date}")
                
            return articles
            
        except Exception as e:
            logger.error(f"Errore nella ricerca: {str(e)}")
            return []

    def _extract_image_url(self, item: Dict) -> str:
        """Estrae l'URL dell'immagine dai metadati dell'articolo"""
        if 'pagemap' in item:
            if 'cse_image' in item['pagemap']:
                return item['pagemap']['cse_image'][0]['src']
            elif 'metatags' in item['pagemap']:
                metatags = item['pagemap']['metatags'][0]
                return metatags.get('og:image', '')
        return ''

    async def get_all_content(self, query: str) -> List[Dict[str, Any]]:
        """Ottiene tutti i contenuti"""
        logger.info(f"Avvio ricerca contenuti per: {query}")
        
        # Usa direttamente get_google_search_content
        results = await self.get_google_search_content(query)
        
        logger.info(f"Trovati {len(results)} risultati totali")
        return results

    def test_connection(self):
        try:
            service = build(
                "customsearch", 
                "v1",
                developerKey=self.google_api_key,
                cache_discovery=False
            )
            
            test_params = {
                'q': 'test',
                'cx': self.google_cse_id,
                'num': 1,
                'safe': 'active'
            }
            
            logger.info(f"Test di connessione con parametri: {test_params}")
            result = service.cse().list(**test_params).execute()
            logger.info("Test di connessione completato con successo")
            return True
            
        except Exception as e:
            logger.error(f"Test di connessione fallito: {str(e)}")
            return False

    def search_articles(self, query):
        try:
            logger.info(f"Google Custom Search per: {query}")
            
            # Pulisci la query
            cleaned_query = query.strip()
            if not cleaned_query:
                logger.error("Query vuota")
                return []

            # Configura il servizio
            service = build(
                "customsearch", 
                "v1",
                developerKey=self.google_api_key,
                cache_discovery=False
            )
            
            # Semplifica al massimo i parametri di ricerca
            search_params = {
                'q': cleaned_query,
                'cx': self.google_cse_id
            }
            
            logger.info(f"Tentativo di ricerca con parametri minimi: {search_params}")
            
            try:
                # Ottieni l'URL della richiesta senza eseguirla
                request = service.cse().list(**search_params)
                logger.info(f"URL richiesta generato: {request.uri}")
                
                # Esegui la richiesta
                result = request.execute()
                
                if 'items' not in result:
                    logger.warning(f"Nessun risultato trovato per: {query}")
                    return []
                    
                logger.info(f"Risposta completa API: {result}")    
                return result['items']
                
            except HttpError as e:
                error_content = json.loads(e.content.decode())
                logger.error(f"Errore Google Custom Search: status {e.resp.status}")
                logger.error(f"Dettagli errore completi: {error_content}")
                logger.error(f"Headers richiesta: {e.resp.headers}")
                logger.error(f"URL richiesta fallita: {e.uri}")
                return []
                
        except Exception as e:
            logger.error(f"Errore generico nella ricerca: {str(e)}")
            logger.error(f"Tipo errore: {type(e)}")
            import traceback
            logger.error(f"Traceback completo: {traceback.format_exc()}")
            return []

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