import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialContact {
  final String type;
  final String value;
  final String? url;

  SocialContact({
    required this.type,
    required this.value,
    this.url,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'value': value,
    'url': url,
  };

  factory SocialContact.fromMap(Map<String, dynamic> map) => SocialContact(
    type: map['type'],
    value: map['value'],
    url: map['url'],
  );
}

class SocialContactsManager extends StatefulWidget {
  final String userId;
  final List<SocialContact> contacts;

  const SocialContactsManager({
    Key? key,
    required this.userId,
    required this.contacts,
  }) : super(key: key);

  @override
  State<SocialContactsManager> createState() => _SocialContactsManagerState();
}

class _SocialContactsManagerState extends State<SocialContactsManager> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedType = 'LinkedIn';

  final List<String> _socialTypes = [
    'LinkedIn',
    'GitHub',
    'Twitter',
    'Instagram',
    'Website',
    'Email',
    'Phone',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      appBar: AppBar(
        title: const Text('Gestisci Social e Contatti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.contacts[index];
          return ListTile(
            leading: Icon(
              _getIconForType(contact.type),
              color: Colors.white,
            ),
            title: Text(
              contact.value,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              contact.type,
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteContact(index),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'LinkedIn':
        return Icons.photo_camera;
      case 'GitHub':
        return Icons.code;
      case 'Twitter':
        return Icons.photo_camera;
      case 'Instagram':
        return Icons.photo_camera;
      case 'Website':
        return Icons.language;
      case 'Email':
        return Icons.email;
      case 'Phone':
        return Icons.phone;
      default:
        return Icons.link;
    }
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Aggiungi Contatto',
          style: TextStyle(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _socialTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Valore',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v?.isEmpty ?? true ? 'Richiesto' : null,
              ),
              if (_selectedType != 'Phone' && _selectedType != 'Email')
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL (opzionale)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
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
            onPressed: _saveContact,
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      final contact = SocialContact(
        type: _selectedType,
        value: _valueController.text,
        url: _urlController.text.isEmpty ? null : _urlController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('contacts')
          .add(contact.toMap());

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    }
  }

  void _deleteContact(int index) async {
    // Implementa la logica di eliminazione come fatto per le certificazioni
  }
} 