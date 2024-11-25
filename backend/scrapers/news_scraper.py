# type: ignore
import scrapy
from scrapy.crawler import CrawlerProcess
import json
import datetime
import sys
from urllib.parse import quote

class NewsSpider(scrapy.Spider):
    name = 'news'
    
    def __init__(self, query=None, *args, **kwargs):
        super(NewsSpider, self).__init__(*args, **kwargs)
        self.query = quote(query) if query else ''
        self.results = []
        
    def start_requests(self):
        urls = [
            f'https://news.google.com/search?q={self.query}&hl=it',
            f'https://www.corriere.it/ricerca/?q={self.query}',
            f'https://www.lastampa.it/ricerca?query={self.query}'
        ]
        
        for url in urls:
            yield scrapy.Request(
                url=url, 
                callback=self.parse,
                errback=self.handle_error,
                dont_filter=True,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7'
                }
            )
    
    def handle_error(self, failure):
        self.logger.error(f'Request failed: {failure.request.url}')
        
    def parse(self, response):
        try:
            if 'news.google.com' in response.url:
                articles = response.css('article')[:3]
                for article in articles:
                    item = {
                        'title': article.css('h3 a::text').get() or 'No title',
                        'imageUrl': article.css('figure img::attr(src)').get() or '',
                        'date': article.css('time::text').get() or datetime.datetime.now().strftime('%b %d, %Y'),
                        'content': article.css('.ipQwMb::text').get() or 'No content available',
                        'source': 'Google News'
                    }
                    if item['title'] != 'No title':
                        self.results.append(item)
                    
            elif 'corriere.it' in response.url:
                articles = response.css('.news-card')[:3]
                for article in articles:
                    item = {
                        'title': article.css('h2::text, h3::text').get() or 'No title',
                        'imageUrl': article.css('img::attr(src)').get() or '',
                        'date': article.css('.date::text').get() or datetime.datetime.now().strftime('%b %d, %Y'),
                        'content': article.css('.abstract::text').get() or 'No content available',
                        'source': 'Corriere della Sera'
                    }
                    if item['title'] != 'No title':
                        self.results.append(item)
                    
            elif 'lastampa.it' in response.url:
                articles = response.css('.entry')[:3]
                for article in articles:
                    item = {
                        'title': article.css('h2::text, h3::text').get() or 'No title',
                        'imageUrl': article.css('img::attr(src)').get() or '',
                        'date': article.css('.date::text').get() or datetime.datetime.now().strftime('%b %d, %Y'),
                        'content': article.css('.preview::text').get() or 'No content available',
                        'source': 'La Stampa'
                    }
                    if item['title'] != 'No title':
                        self.results.append(item)
                    
        except Exception as e:
            self.logger.error(f'Error parsing {response.url}: {str(e)}')

def run_spider(query):
    process = CrawlerProcess({
        'USER_AGENT': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'ROBOTSTXT_OBEY': False,
        'DOWNLOAD_DELAY': 2,
        'COOKIES_ENABLED': False
    })
    
    spider = NewsSpider(query=query)
    process.crawl(NewsSpider, query=query)
    process.start()
    return spider.results

if __name__ == "__main__":
    if len(sys.argv) > 1:
        query = sys.argv[1]
        results = run_spider(query)
        print(json.dumps(results)) 