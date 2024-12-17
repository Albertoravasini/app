import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience.dart';
import 'package:intl/intl.dart';

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
        title: const Text('Add Experience', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Start Date Picker
                ListTile(
                  title: Text(
                    'Start Date: ${_startDate != null ? DateFormat('MMM yyyy').format(_startDate!) : 'Select date'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white),
                  onTap: () => _selectDate(context, true),
                ),
                // End Date Picker
                ListTile(
                  title: Text(
                    'End Date: ${_endDate != null ? DateFormat('MMM yyyy').format(_endDate!) : 'Present'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white),
                  onTap: () => _selectDate(context, false),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _saveExperience,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellowAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF282828),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF282828),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          // Only allow end date after start date
          if (_startDate != null && picked.isAfter(_startDate!)) {
            _endDate = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date must be after start date')),
            );
          }
        }
      });
    }
  }

  void _saveExperience() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date')),
        );
        return;
      }

      final experience = Experience(
        title: _titleController.text,
        company: _companyController.text,
        startDate: _startDate!,
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