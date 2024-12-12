import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certification.dart';
import 'package:intl/intl.dart';

class CertificationManager extends StatefulWidget {
  final String userId;
  final List<Certification> certifications;

  const CertificationManager({
    Key? key,
    required this.userId,
    required this.certifications,
  }) : super(key: key);

  @override
  State<CertificationManager> createState() => _CertificationManagerState();
}

class _CertificationManagerState extends State<CertificationManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _issuerController = TextEditingController();
  final _imageUrlController = TextEditingController();
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      appBar: AppBar(
        title: const Text('Gestisci Certificazioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCertificationDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.certifications.length,
        itemBuilder: (context, index) {
          final cert = widget.certifications[index];
          return ListTile(
            leading: cert.imageUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(cert.imageUrl!))
                : const CircleAvatar(child: Icon(Icons.verified_outlined)),
            title: Text(cert.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${cert.issuer} - ${DateFormat('MMM yyyy').format(cert.date)}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCertification(index),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCertificationDialog(BuildContext context) async {
    _date = DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Aggiungi Certificazione',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Ente Certificatore',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Immagine (opzionale)',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              ListTile(
                title: const Text(
                  'Data Conseguimento',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_date!),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date!,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _date = date);
                  }
                },
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
            onPressed: _saveCertification,
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _saveCertification() async {
    if (_formKey.currentState?.validate() ?? false) {
      final certification = Certification(
        title: _titleController.text,
        issuer: _issuerController.text,
        date: _date!,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('certifications')
          .add(certification.toMap());

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    }
  }

  void _deleteCertification(int index) async {
    // Implementa la logica di eliminazione
    final certification = widget.certifications[index];
    // Aggiungi una conferma prima di eliminare
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Conferma eliminazione',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Vuoi eliminare la certificazione "${certification.title}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      // Implementa l'eliminazione effettiva
      setState(() {
        // Aggiorna l'UI
      });
    }
  }
} 