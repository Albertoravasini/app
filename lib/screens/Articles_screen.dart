import 'package:flutter/material.dart';
import '../services/articles_service.dart';

class ArticlesWidget extends StatefulWidget {
  final String videoTitle;
  
  const ArticlesWidget({
    Key? key,
    required this.videoTitle,
  }) : super(key: key);
  
  @override
  State<ArticlesWidget> createState() => _ArticlesWidgetState();
}

class _ArticlesWidgetState extends State<ArticlesWidget> {
  final ArticlesService _articlesService = ArticlesService();
  List<Map<String, dynamic>> articles = [];
  bool isLoading = true;

  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final fetchedArticles = await _articlesService.getRelatedArticles(widget.videoTitle);
      if (mounted) {
        setState(() {
          articles = fetchedArticles.map((article) {
            DateTime date;
            try {
              date = DateTime.parse(article['date'] ?? '');
            } catch (e) {
              date = DateTime.now();
            }

            final formattedDate = '${date.day}/${date.month}/${date.year}';

            final source = article['source'] ?? 'Fonte sconosciuta';

            return {
              ...article,
              'date': formattedDate,
              'source': source,
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Errore nel caricamento degli articoli: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:  const Color(0xFF121212),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 43, bottom: 16),
              child: Container(
                height: 48,
                decoration: ShapeDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      width: 1,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(
                        Icons.search,
                        size: 24,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: articles.isEmpty ? 1 : articles.length,
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  if (articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 48,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun articolo disponibile',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final article = articles[index];
                  double difference = index - _currentPage;
                  double scale = 1 - (difference.abs() * 0.1).clamp(0.0, 0.3);
                  double opacity = 1 - (difference.abs() * 0.3).clamp(0.0, 0.7);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        onTap: () {
                          print('Debug - Content: ${article['content']?.length ?? 0}');
                          print('Debug - Full Content: ${article['full_content']?.length ?? 0}');
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(
                                title: article['title'] ?? '',
                                imageUrl: article['imageUrl'] ?? '',
                                date: article['date'] ?? '',
                                content: article['content'] ?? '',
                                fullContent: article['full_content'] ?? article['content'] ?? '',
                                source: article['source'] ?? 'Fonte sconosciuta',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0 + (difference.abs() * 5),
                          ),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.network(
                                        article['imageUrl'] ?? "https://via.placeholder.com/324x148",
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            "https://via.placeholder.com/324x148",
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        article['source'] ?? 'Fonte sconosciuta',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                article['title'] ?? 'Titolo non disponibile',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    article['date'] ?? 'Data non disponibile',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                article['content'] ?? 'Contenuto non disponibile',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Nuovo screen per il dettaglio dell'articolo
class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String date;
  final String content;
  final String fullContent;
  final String source;

  const ArticleDetailScreen({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.content,
    required this.fullContent,
    required this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Debug - DetailScreen Content Length: ${content.length}');
    print('Debug - DetailScreen Full Content Length: ${fullContent.length}');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con immagine
            Stack(
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 50,
                        ),
                      );
                    },
                  ),
                // Pulsante indietro
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Contenuto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Data e fonte
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          source,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Contenuto completo
                  Text(
                    fullContent.length > content.length ? fullContent : content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}