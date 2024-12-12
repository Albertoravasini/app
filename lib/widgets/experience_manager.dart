import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience.dart';

class ExperienceManager extends StatefulWidget {
  final String userId;
  final List<Experience> experiences;

  const ExperienceManager({
    Key? key,
    required this.userId,
    required this.experiences,
  }) : super(key: key);

  @override
  State<ExperienceManager> createState() => _ExperienceManagerState();
}

class _ExperienceManagerState extends State<ExperienceManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      appBar: AppBar(
        title: const Text('Gestisci Esperienze'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExperienceDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.experiences.length,
        itemBuilder: (context, index) {
          final exp = widget.experiences[index];
          return ListTile(
            title: Text(exp.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(exp.company, style: const TextStyle(color: Colors.white70)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteExperience(index),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddExperienceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Aggiungi Esperienza', style: TextStyle(color: Colors.white)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Azienda'),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
              // Date pickers...
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: _saveExperience,
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _saveExperience() async {
    if (_formKey.currentState?.validate() ?? false) {
      final experience = Experience(
        title: _titleController.text,
        company: _companyController.text,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate,
        description: _descriptionController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('experiences')
          .add(experience.toMap());

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    }
  }

  void _deleteExperience(int index) async {
    // Implementa la logica di eliminazione
  }
} 