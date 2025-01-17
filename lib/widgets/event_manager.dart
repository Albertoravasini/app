import 'package:Just_Learn/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EventManager extends StatefulWidget {
  final String userId;
  final Event? event;

  const EventManager({
    Key? key,
    required this.userId,
    this.event,
  }) : super(key: key);

  @override
  State<EventManager> createState() => _EventManagerState();
}

class _EventManagerState extends State<EventManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isOnline = false;
  String? _meetingLink;
  String? _selectedImageUrl;
  File? _imageFile;
  bool _isSubscriptionRequired = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _maxParticipantsController.text = widget.event!.maxParticipants.toString();
      _locationController.text = widget.event!.location ?? '';
      _priceController.text = widget.event!.price?.toString() ?? '';
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _isOnline = widget.event!.isOnline;
      _meetingLink = widget.event!.meetingLink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(widget.event != null ? 'Modifica Evento' : 'Nuovo Evento'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _titleController,
              label: 'Titolo evento',
              validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descrizione',
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Data inizio',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Data fine',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _maxParticipantsController,
              label: 'Numero massimo partecipanti',
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo evento',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'Evento Online',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _isOnline,
                    onChanged: (value) => setState(() => _isOnline = value),
                    activeColor: Colors.yellowAccent,
                  ),
                  if (_isOnline) ...[
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: TextEditingController(text: _meetingLink),
                      label: 'Link riunione',
                      onChanged: (value) => _meetingLink = value,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Luogo',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Impostazioni accesso',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'Richiedi Subscription',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Solo gli utenti abbonati potranno partecipare',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    value: _isSubscriptionRequired,
                    onChanged: (value) => setState(() => _isSubscriptionRequired = value),
                    activeColor: Colors.yellowAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.event != null ? 'Aggiorna Evento' : 'Crea Evento',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        subtitle: Text(
          value != null ? DateFormat('dd/MM/yyyy HH:mm').format(value) : 'Seleziona',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2025),
          );
          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
            );
            if (time != null) {
              onChanged(DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              ));
            }
          }
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Immagine evento',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(12),
              image: (_imageFile != null)
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : (_selectedImageUrl != null)
                      ? DecorationImage(
                          image: NetworkImage(_selectedImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: (_imageFile == null && _selectedImageUrl == null)
                ? const Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      color: Colors.white54,
                      size: 40,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _selectedImageUrl;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('event_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento dell\'immagine: $e')),
      );
      return null;
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona le date dell\'evento')),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La data di fine deve essere successiva all\'inizio')),
        );
        return;
      }

      try {
        final imageUrl = await _uploadImage();
        
        final eventData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'teacherId': widget.userId,
          'maxParticipants': int.parse(_maxParticipantsController.text),
          'isOnline': _isOnline,
          'meetingLink': _meetingLink,
          'location': _isOnline ? null : _locationController.text,
          'price': _priceController.text.isNotEmpty
              ? double.parse(_priceController.text)
              : null,
          'imageUrl': imageUrl,
          'isSubscriptionRequired': _isSubscriptionRequired,
        };

        if (widget.event != null) {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event!.id)
              .update(eventData);
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Evento aggiornato con successo!')),
            );
          }
        } else {
          await FirebaseFirestore.instance
              .collection('events')
              .add(eventData);
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Evento creato con successo!')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
} 