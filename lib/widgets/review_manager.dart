import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';

class ReviewManager extends StatefulWidget {
  final String userId;
  final List<Review> reviews;

  const ReviewManager({
    Key? key,
    required this.userId,
    required this.reviews,
  }) : super(key: key);

  @override
  State<ReviewManager> createState() => _ReviewManagerState();
}

class _ReviewManagerState extends State<ReviewManager> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      appBar: AppBar(
        title: const Text('Gestisci Recensioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReviewDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.reviews.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final review = widget.reviews[index];
          return Card(
            color: const Color(0xFF282828),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: review.userImage != null
                            ? NetworkImage(review.userImage!)
                            : null,
                        child: review.userImage == null
                            ? Text(review.userName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(review.date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.yellowAccent,
                          size: 16,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review.comment,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddReviewDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Aggiungi Recensione',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.yellowAccent,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                )),
              ),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Commento',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: _saveReview,
            child: const Text('Pubblica'),
          ),
        ],
      ),
    );
  }

  void _saveReview() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Implementa il salvataggio della recensione
      final review = {
        'userName': 'Current User', // Sostituisci con il nome utente corrente
        'rating': _rating,
        'comment': _commentController.text,
        'date': DateTime.now(),
        'userImage': null, // Sostituisci con l'immagine utente corrente
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('reviews')
          .add(review);

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    }
  }
} 