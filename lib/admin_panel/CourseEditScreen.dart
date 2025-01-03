// lib/admin_panel/course_edit_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../models/level.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class CourseEditScreen extends StatefulWidget {
  final Course? course;

  const CourseEditScreen({Key? key, this.course}) : super(key: key);

  @override
  _CourseEditScreenState createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  Section? _selectedSection;
  String? _selectedTopic;
  String? _courseTitle;
  String? _courseDescription;
  int? _courseCost;
  List<String> _topics = [];
  List<Section> _sections = [];
  bool _isEditing = false;
  String? _coverImageUrl;

  // Nuovi campi per fonti, ringraziamenti e approfondimenti
  List<String> _sources = [];
  List<String> _acknowledgments = [];
  List<String> _recommendedBooks = [];
  List<String> _recommendedPodcasts = [];
  List<String> _recommendedWebsites = [];

  final List<String> _stepTitles = ['Basic', 'Content', 'Resources', 'Summary'];

  int? _expandedStepIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Column(
            children: [
              // Header semplificato con lo stesso colore di sfondo
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF181819),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1.5),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / _stepTitles.length,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${_currentStep + 1}/${_stepTitles.length}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenuto principale
              Expanded(
                child: _currentStep == 0
                    ? _buildBasicInfoStep()
                    : _currentStep == 1
                        ? _buildContentStep()
                        : _currentStep == 2
                            ? _buildResourcesStep()
                            : _buildSummaryStep(),
              ),
              
              // Pulsanti di navigazione con lo stesso colore di sfondo
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF181819),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                        onPressed: () => _handleStepChange(_currentStep - 1),
                      ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        if (_currentStep < _stepTitles.length - 1) {
                          _handleStepChange(_currentStep + 1);
                        } else {
                          _saveCourse();
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Colors.yellowAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentStep == _stepTitles.length - 1 ? 'Save' : 'Next',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentStep < _stepTitles.length - 1)
                            Icon(Icons.arrow_forward, color: Colors.black, size: 16),
                        ],
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

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        Card(
          color: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.yellowAccent.withOpacity(0.3),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icona
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: Colors.yellowAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Course Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Form fields
                DropdownButtonFormField<String>(
                  value: _selectedTopic,
                  decoration: _inputDecoration('Topic'),
                  dropdownColor: const Color(0xFF282828),
                  items: _topics.map((topic) => DropdownMenuItem(
                    value: topic,
                    child: Text(
                      topic,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedTopic = value),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _courseTitle,
                  decoration: _inputDecoration('Course Title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                  onChanged: (value) => _courseTitle = value,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _courseDescription,
                  decoration: _inputDecoration('Description'),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                  maxLines: 3,
                  onChanged: (value) => _courseDescription = value,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _courseCost?.toString(),
                  decoration: _inputDecoration('Cost (coins)'),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _courseCost = int.tryParse(value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentStep() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildAddChapterCard(),
              ..._sections.map((section) => _buildChapterCard(section)).toList(),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.white.withOpacity(0.1)),
        Expanded(
          child: _selectedSection == null
              ? Center(
                  child: Text(
                    'Select a chapter',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ReorderableListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _selectedSection!.steps.length + 1,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < _selectedSection!.steps.length) {
                        if (newIndex > _selectedSection!.steps.length) {
                          newIndex = _selectedSection!.steps.length;
                        }
                        final item = _selectedSection!.steps.removeAt(oldIndex);
                        _selectedSection!.steps.insert(
                          newIndex > oldIndex ? newIndex - 1 : newIndex, 
                          item
                        );
                      }
                    });
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    if (index == _selectedSection!.steps.length) {
                      return _buildAddStepButton();
                    }
                    return _buildCompactStepCard(
                      _selectedSection!.steps[index], 
                      index,
                      key: ValueKey(_selectedSection!.steps[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCompactStepCard(LevelStep step, int index, {Key? key}) {
    bool isExpanded = _expandedStepIndex == index;
    
    return Card(
      key: key,
      margin: EdgeInsets.only(bottom: 8),
      color: Color(0xFF282828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedStepIndex = isExpanded ? null : index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sempre visibile
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: Colors.white54,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Icon(
                      step.type == 'video' ? Icons.play_circle_outline : Icons.quiz_outlined,
                      color: Colors.yellowAccent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.content,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.edit, color: Colors.white54, size: 18),
                      onPressed: () => _editStepDialog(
                        _selectedSection!, 
                        _sections.indexOf(_selectedSection!), 
                        step, 
                        index
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
              
              // Contenuto espanso
              if (isExpanded) ...[
                Divider(color: Colors.white.withOpacity(0.1)),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.type == 'video') ...[
                        if (step.videoUrl != null)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => VideoPlayerDialog(videoUrl: step.videoUrl!),
                              );
                            },
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.yellowAccent,
                                    size: 24,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Play video',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (step.duration != null)
                                          Text(
                                            'Duration: ${step.duration}s',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ] else if (step.type == 'question') ...[
                        Text(
                          'Question:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...?step.choices?.map((choice) => 
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  choice == step.correctAnswer 
                                    ? Icons.check_circle 
                                    : Icons.radio_button_unchecked,
                                  color: choice == step.correctAnswer 
                                    ? Colors.green 
                                    : Colors.white54,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  choice,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editStepDialog(
                              _selectedSection!, 
                              _sections.indexOf(_selectedSection!), 
                              step, 
                              index
                            ),
                            icon: Icon(Icons.edit, size: 16),
                            label: Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.yellowAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStepButton() {
    return Card(
      key: ValueKey('add_step'),
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.yellowAccent.withOpacity(0.3),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () => _addStepDialog(_selectedSection!, _sections.indexOf(_selectedSection!)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.yellowAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Step',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTopics();

    if (widget.course != null) {
      _isEditing = true;
      _selectedTopic = widget.course!.topic;
      _courseTitle = widget.course!.title;
      _courseDescription = widget.course!.description;
      _courseCost = widget.course!.cost;
      _sections = widget.course!.sections;
      _coverImageUrl = widget.course!.coverImageUrl;
      _selectedSection = _sections.isNotEmpty ? _sections[0] : null;

      _sources = List.from(widget.course!.sources);
      _acknowledgments = List.from(widget.course!.acknowledgments);
      _recommendedBooks = List.from(widget.course!.recommendedBooks);
      _recommendedPodcasts = List.from(widget.course!.recommendedPodcasts);
      _recommendedWebsites = List.from(widget.course!.recommendedWebsites);
    } else {
      _sections = [];
      _selectedSection = null;
    }
  }

  Future<void> _loadTopics() async {
    final topicsCollection = FirebaseFirestore.instance.collection('topics');
    final querySnapshot = await topicsCollection.get();
    setState(() {
      _topics = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Funzione per aggiungere elementi alle liste
  void _addItemDialog(String title, Function(String) onAdd) {
    String? newItem;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          content: TextFormField(
            decoration: InputDecoration(
              labelText: title,
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              newItem = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                if (newItem != null && newItem!.isNotEmpty) {
                  onAdd(newItem!);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // Funzione per rimuovere elementi dalle liste
  void _removeItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  void _addSection() {
    String? sectionTitle;
    String? imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.library_books_outlined,
                  color: Colors.yellowAccent,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'New Chapter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: _inputDecoration('Titolo Capitolo'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => sectionTitle = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('URL Immagine (opzionale)'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => imageUrl = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (sectionTitle != null && sectionTitle!.isNotEmpty) {
                  setState(() {
                    _sections.add(Section(
                      title: sectionTitle!,
                      steps: [],
                      imageUrl: imageUrl,
                      sectionNumber: _sections.length + 1,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Create',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editSection(Section section, int index) {
    String? sectionTitle = section.title;
    String? imageUrl = section.imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.yellowAccent,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Edit Chapter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: section.title,
                decoration: _inputDecoration('Chapter Title'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => sectionTitle = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: section.imageUrl,
                decoration: _inputDecoration('Image URL (optional)'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => imageUrl = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _deleteSection(index),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (sectionTitle != null && sectionTitle!.isNotEmpty) {
                  setState(() {
                    _sections[index].title = sectionTitle!;
                    _sections[index].imageUrl = imageUrl;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSection(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete Chapter',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this chapter?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sections.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chapter deleted successfully')),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _addStepDialog(Section section, int sectionIndex) {
    String? stepType;
    String? videoTitle;
    String? videoUrl;
    File? videoFile;
    String? questionContent;
    List<String> choices = [];
    String? correctAnswer;
    String? explanation;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF282828),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      stepType == 'video' ? Icons.play_circle_outline : 
                      stepType == 'question' ? Icons.quiz_outlined : 
                      Icons.add_circle_outline,
                      color: Colors.yellowAccent,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'New Step',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Step Type'),
                      dropdownColor: const Color(0xFF282828),
                      value: stepType,
                      items: [
                        DropdownMenuItem(
                          value: 'video',
                          child: Text('Video', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'question',
                          child: Text('Question', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => stepType = value);
                      },
                    ),
                    SizedBox(height: 16),
                    if (stepType == 'video') ...[
                      TextFormField(
                        decoration: _inputDecoration('Video Title'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => videoTitle = value,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                          foregroundColor: Colors.yellowAccent,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.yellowAccent),
                          ),
                        ),
                        icon: Icon(Icons.upload_file),
                        label: Text('Select Video'),
                        onPressed: isUploading ? null : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.video,
                            allowMultiple: false,
                          );

                          if (result != null) {
                            setDialogState(() {
                              videoFile = File(result.files.single.path!);
                            });
                          }
                        },
                      ),
                    ] else if (stepType == 'question') ...[
                      TextFormField(
                        decoration: _inputDecoration('Question'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => questionContent = value,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Options (comma separated)'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          choices = value.split(',').map((e) => e.trim()).toList();
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Correct Answer'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => correctAnswer = value,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Explanation'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => explanation = value,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: isUploading ? null : () async {
                    if (stepType == 'video' && videoFile != null && videoTitle != null && videoTitle!.isNotEmpty) {
                      try {
                        setDialogState(() {
                          isUploading = true;
                        });

                        // Verifica che il file esista e sia accessibile
                        if (!await videoFile!.exists()) {
                          throw Exception('Il file video non esiste o non è accessibile');
                        }

                        // Verifica la dimensione del file
                        final fileSize = await videoFile!.length();
                        print('Dimensione file: ${fileSize / (1024 * 1024)} MB');

                        await _uploadVideo(
                          videoFile!,
                          (String videoUrl) {
                            if (mounted) {
                              setState(() {
                                section.steps.add(LevelStep(
                                  type: 'video',
                                  content: videoTitle!,
                                  videoUrl: videoUrl,
                                  thumbnailUrl: null,
                                  isShort: false,
                                  topic: widget.course?.topic ?? '',
                                ));
                              });
                            }
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Video caricato con successo!')),
                            );
                          },
                          (String error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Errore: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        );
                      } catch (e) {
                        print('Errore durante l\'upload: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Errore durante l\'upload: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setDialogState(() {
                            isUploading = false;
                          });
                        }
                      }
                    } else if (stepType == 'question' &&
                        questionContent != null &&
                        questionContent!.isNotEmpty &&
                        correctAnswer != null &&
                        correctAnswer!.isNotEmpty &&
                        choices.isNotEmpty) {
                      setState(() {
                        section.steps.add(LevelStep(
                          type: 'question',
                          content: questionContent!,
                          choices: choices,
                          correctAnswer: correctAnswer!,
                          explanation: explanation,
                          topic: widget.course?.topic ?? '',
                          videoUrl: null,
                          thumbnailUrl: null,
                          isShort: false,
                        ));
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editStepDialog(Section section, int sectionIndex, LevelStep step, int stepIndex) {
    String? stepType = step.type;
    String? content = step.content;
    String? videoUrl = step.videoUrl;
    String? videoTitle = step.type == 'video' ? step.content : null;
    String? correctAnswer = step.correctAnswer;
    List<String>? choices = step.choices;
    String? explanation = step.explanation;
    String? thumbnailUrl = step.thumbnailUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF282828),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.yellowAccent,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Edit Step',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: stepType,
                      decoration: _inputDecoration('Step Type'),
                      dropdownColor: const Color(0xFF282828),
                      items: ['video', 'question'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          stepType = value;
                        });
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    if (stepType == 'video') ...[
                      TextFormField(
                        initialValue: videoUrl,
                        decoration: _inputDecoration('YouTube Video ID'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          videoUrl = value;
                          setState(() {
                            thumbnailUrl = 'https://img.youtube.com/vi/$value/0.jpg';
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: videoTitle,
                        decoration: _inputDecoration('Video Title'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => videoTitle = value,
                      ),
                    ] else if (stepType == 'question') ...[
                      TextFormField(
                        initialValue: content,
                        decoration: _inputDecoration('Question Content'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => content = value,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: choices?.join(', '),
                        decoration: _inputDecoration('Options (comma separated)'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          choices = value.split(',').map((e) => e.trim()).toList();
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: correctAnswer,
                        decoration: _inputDecoration('Correct Answer'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => correctAnswer = value,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        initialValue: explanation,
                        decoration: _inputDecoration('Explanation'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) => explanation = value,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _deleteStep(sectionIndex, stepIndex),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // ... logica esistente per il salvataggio ...
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteStep(int sectionIndex, int stepIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete Step',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this step?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sections[sectionIndex].steps.removeAt(stepIndex);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Step deleted successfully')),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

void _saveCourse() async {
  if (_formKey.currentState != null && _formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    
    // Ottieni i dati dell'utente corrente
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated')),
      );
      return;
    }

    // Recupera i dati dell'autore da Firestore
    final authorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!authorDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User data not found')),
      );
      return;
    }

    final authorData = authorDoc.data()!;
      
    final course = Course(
      id: widget.course?.id ?? '',
      title: _courseTitle ?? '',
      description: _courseDescription ?? '',
      cost: _courseCost ?? 0,
      visible: true,
      sections: _sections,
      topic: _selectedTopic ?? '',
      subtopic: '',
      thumbnailUrl: widget.course?.thumbnailUrl ?? '',
      coverImageUrl: _coverImageUrl ?? widget.course?.coverImageUrl ?? '',
      sources: _sources,
      acknowledgments: _acknowledgments,
      recommendedBooks: _recommendedBooks,
      recommendedPodcasts: _recommendedPodcasts,
      recommendedWebsites: _recommendedWebsites,
      rating: widget.course?.rating ?? 0.0,
      totalRatings: widget.course?.totalRatings ?? 0,
      // Aggiorna i dati dell'autore
      authorId: currentUser.uid,
      authorName: authorData['name'] ?? 'Anonymous User',
      authorProfileUrl: authorData['profileImageUrl'] ?? '',
    );

    try {
      if (widget.course != null) {
        // Aggiorna il corso esistente
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.course!.id)
            .update(course.toMap());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully')),
        );
      } else {
        // Crea un nuovo corso
        await FirebaseFirestore.instance
            .collection('courses')
            .add(course.toMap());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New course created successfully')),
        );
      }
      
      Navigator.pop(context);
    } catch (e) {
      print('Errore durante il salvataggio: $e'); // Per debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il salvataggio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // Aggiungi questa funzione per migrare i corsi esistenti
  Future<void> migrateExistingCourses() async {
    try {
      final coursesRef = FirebaseFirestore.instance.collection('courses');
      final QuerySnapshot coursesSnapshot = await coursesRef.get();

      // Ottieni i dati dell'admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('YOUR_ADMIN_USER_ID') // Sostituisci con l'ID del tuo utente admin
          .get();

      if (!adminDoc.exists) {
        throw Exception('Admin user document not found');
      }

      final adminData = adminDoc.data()!;
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data() as Map<String, dynamic>;
        
        // Verifica se il corso ha già i campi dell'autore
        if (!courseData.containsKey('authorId')) {
          batch.update(doc.reference, {
            'authorId': adminDoc.id,
            'authorName': adminData['name'] ?? 'JustLearn Admin',
            'authorProfileUrl': adminData['profileImageUrl'] ?? '',
          });
        }
      }

      await batch.commit();
      print('Migration completed successfully');
    } catch (e) {
      print('Error during migration: $e');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white70,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white24,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.yellowAccent,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildResourcesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResourceSection(
            title: 'Sources',
            icon: Icons.source_outlined,
            items: _sources,
            onAdd: () => _addResourceDialog(
              'Add Source',
              'Enter source reference',
              (item) => setState(() => _sources.add(item)),
            ),
            onDelete: (index) => setState(() => _sources.removeAt(index)),
          ),
          SizedBox(height: 16),
          _buildResourceSection(
            title: 'Recommended Books',
            icon: Icons.book_outlined,
            items: _recommendedBooks,
            onAdd: () => _addResourceDialog(
              'Add Book',
              'Enter book title',
              (item) => setState(() => _recommendedBooks.add(item)),
            ),
            onDelete: (index) => setState(() => _recommendedBooks.removeAt(index)),
          ),
          SizedBox(height: 16),
          _buildResourceSection(
            title: 'Recommended Podcasts',
            icon: Icons.headphones_outlined,
            items: _recommendedPodcasts,
            onAdd: () => _addResourceDialog(
              'Add Podcast',
              'Enter podcast name',
              (item) => setState(() => _recommendedPodcasts.add(item)),
            ),
            onDelete: (index) => setState(() => _recommendedPodcasts.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onDelete,
  }) {
    return Card(
      color: const Color(0xFF282828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.yellowAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.yellowAccent,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Colors.yellowAccent,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items added',
                style: TextStyle(
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      items[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => onDelete(index),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _addResourceDialog(String title, String hint, Function(String) onAdd) {
    String? newItem;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.yellowAccent,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: TextFormField(
            decoration: _inputDecoration(hint),
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
            onChanged: (value) => newItem = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (newItem != null && newItem!.isNotEmpty) {
                  onAdd(newItem!);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleStepChange(int step) {
    setState(() {
      _currentStep = step;
      if (step == 1 && _sections.isNotEmpty && _selectedSection == null) {
        _selectedSection = _sections[0];
      }
    });
  }

  Widget _buildAddChapterCard() {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      child: Card(
        color: Color(0xFF282828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.yellowAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: _addSection,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.yellowAccent,
                  size: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'New',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(Section section) {
    bool isSelected = _selectedSection?.title == section.title;
    
    return Container(
      width: 140,
      height: 100,
      margin: EdgeInsets.only(right: 8),
      child: Card(
        color: isSelected ? Colors.yellowAccent.withOpacity(0.1) : Color(0xFF282828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.yellowAccent : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _selectedSection = section),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ch. ${section.sectionNumber}',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editSection(section, _sections.indexOf(section)),
                      child: Icon(Icons.edit, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      section.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.list, size: 14, color: Colors.white54),
                    SizedBox(width: 4),
                    Text(
                      '${section.steps.length} step',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadVideo(File videoFile, Function(String) onSuccess, Function(String) onError) async {
    try {
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('course_videos')
          .child(fileName);

      // Leggi il file come bytes
      final bytes = await videoFile.readAsBytes();
      
      // Crea un upload task senza metadata
      final uploadTask = videoRef.putData(
        bytes,
        firebase_storage.SettableMetadata(contentType: 'video/mp4')
      );

      // Monitora il progresso
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          }
        },
        onError: (error) {
          print('Errore durante il monitoraggio dell\'upload: $error');
        },
        cancelOnError: false,
      );

      // Attendi il completamento
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload completed. URL: $downloadUrl');
      onSuccess(downloadUrl);
      
    } catch (e) {
      print('Detailed error during upload: $e');
      onError(e.toString());
    }
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF282828),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.yellowAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icona
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.summarize_outlined,
                          color: Colors.yellowAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Course Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary items
                  _buildSummaryItem('Title', _courseTitle ?? 'Not specified'),
                  _buildSummaryItem('Topic', _selectedTopic ?? 'Not specified'),
                  _buildSummaryItem('Chapters', '${_sections.length}'),
                  _buildSummaryItem('Total Steps', _getTotalSteps()),
                  _buildSummaryItem('Cost', '${_courseCost ?? 0} coins'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalSteps() {
    int total = 0;
    for (var section in _sections) {
      total += section.steps.length;
    }
    return total.toString();
  }
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({required this.videoUrl});

  @override
  _VideoPlayerDialogState createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 9/16,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      placeholder: Center(
        child: CircularProgressIndicator(
          color: Colors.yellowAccent,
        ),
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.yellowAccent,
        handleColor: Colors.yellowAccent,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 9/16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : Center(
                        child: CircularProgressIndicator(
                          color: Colors.yellowAccent,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 8),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
