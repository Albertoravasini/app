import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../services/articles_service.dart';
import '../services/ai_service.dart';

class ArticlesWidget extends StatefulWidget {
  final String videoTitle;
  final String levelId;
  
  const ArticlesWidget({
    Key? key,
    required this.videoTitle,
    required this.levelId,
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
    print('Inizializzazione ArticlesWidget');
    print('Video Title: ${widget.videoTitle}');
    print('Level ID: ${widget.levelId}');
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
      if (widget.videoTitle.isEmpty || widget.levelId.isEmpty) {
        print('ERRORE: videoTitle o levelId mancanti');
        print('videoTitle: ${widget.videoTitle}');
        print('levelId: ${widget.levelId}');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final fetchedArticles = await _articlesService.getRelatedArticles(
        widget.videoTitle,
        widget.levelId,
      );
      
      if (mounted) {
        setState(() {
          articles = fetchedArticles;
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
                          Posthog().capture(
                            eventName: 'article_clicked',
                            properties: {
                              'article_title': article['title'],
                              'article_source': article['source'],
                              'video_title': widget.videoTitle,
                              'level_id': widget.levelId,
                            },
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(
                                title: article['title'] ?? '',
                                imageUrl: article['imageUrl'] ?? '',
                                date: article['date'] ?? '',
                                content: article['content'] ?? '',
                                fullContent: article['full_content'] ?? '',
                                source: article['source'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
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
                                        article['imageUrl'] ?? "https://placehold.co/324x148",
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.network(
                                            "https://placehold.co/324x148",
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey[800],
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 48,
                                                color: Colors.white.withOpacity(0.5),
                                              ),
                                            ),
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
                              Expanded(
                                child: Text(
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
class ArticleDetailScreen extends StatefulWidget {
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
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final AiService _aiService = AiService();
  Map<String, String>? summary;
  bool isLoadingSummary = false;

  Future<void> _generateSummary() async {
    setState(() {
      isLoadingSummary = true;
    });

    try {
      final result = await _aiService.getSummary(widget.fullContent);
      setState(() {
        summary = result;
        isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSummary = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella generazione del riassunto')),
      );
    }
  }

  String _formatContent(String content) {
    // Dividi il contenuto in paragrafi
    final paragraphs = content.split('. ');
    
    // Crea sezioni logiche basate sulla lunghezza del testo
    List<String> formattedParagraphs = [];
    String currentParagraph = '';
    
    for (var sentence in paragraphs) {
      if (currentParagraph.length > 300) {
        formattedParagraphs.add(currentParagraph.trim());
        currentParagraph = '';
      }
      currentParagraph += sentence + '. ';
    }
    
    if (currentParagraph.isNotEmpty) {
      formattedParagraphs.add(currentParagraph.trim());
    }
    
    return formattedParagraphs.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
          scrolledUnderElevation: 0, // Rimuove l'effetto di elevazione durante lo scroll
          shadowColor: Colors.transparent, // Rimuove l'ombra
          surfaceTintColor: Colors.transparent, // Rimuove la tinta di superficie di Material 3
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          forceMaterialTransparency: true, // Forza la trasparenza completa
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
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
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (widget.imageUrl.isNotEmpty)
                    Image.network(
                      widget.imageUrl,
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
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titolo
                    Text(
                      widget.title,
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
                          widget.date,
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
                            widget.source,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Pulsante AI separato
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: isLoadingSummary ? null : _generateSummary,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Summary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (isLoadingSummary)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    
                    if (summary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Summary',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                summary?['summary'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              if (summary?['key_learning'] != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Key Learning',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (summary?['key_learning'] ?? '')
                                      .split('\n')
                                      .map((point) => point.trim())
                                      .where((point) => point.isNotEmpty)
                                      .map((point) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 14,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    point,
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontSize: 14,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Contenuto principale
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _formatContent(widget.fullContent.length > widget.content.length ? widget.fullContent : widget.content)
                            .split('\n\n')
                            .map((paragraph) => Column(
                                  children: [
                                    Text(
                                      paragraph,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (paragraph != _formatContent(widget.fullContent.length > widget.content.length ? widget.fullContent : widget.content)
                                        .split('\n\n')
                                        .last)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}