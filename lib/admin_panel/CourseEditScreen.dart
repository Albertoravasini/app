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
  bool _isSubscriptionRequired = false;
   Course? _course;  // Aggiungi quest

  // Nuovi campi per fonti, ringraziamenti e approfondimenti
  List<String> _sources = [];
  List<String> _acknowledgments = [];
  List<String> _recommendedBooks = [];
  List<String> _recommendedPodcasts = [];
  List<String> _recommendedWebsites = [];

  final List<String> _stepTitles = ['Basic', 'Content', 'Resources', 'Summary'];

  int? _expandedStepIndex;
  Map<int, double> _uploadProgress = {};  // Per tracciare il progresso di upload per ogni step

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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    decoration: _inputDecoration('Topic').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add, color: Colors.yellowAccent),
                        onPressed: () => _showAddTopicDialog(context),
                      ),
                    ),
                    dropdownColor: const Color(0xFF282828),
                    items: [
                      ..._topics.map((topic) => DropdownMenuItem(
                        value: topic,
                        child: Text(
                          topic,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      )).toList(),
                    ],
                    onChanged: (value) => setState(() => _selectedTopic = value),
                  ),
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
                const SizedBox(height: 16),
                
                // Aggiungi lo switch per la subscription
                SwitchListTile(
                  title: const Text(
                    'Subscription Required',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Only subscribers can access this course',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _isSubscriptionRequired,
                  onChanged: (bool value) {
                    setState(() {
                      _isSubscriptionRequired = value;
                      if (_course != null) {
                        _course!.isSubscriptionRequired = value;
                      }
                    });
                  },
                  activeColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.white24,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTopicDialog(BuildContext context) async {
    String? newTopic;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text(
          'Add New Topic',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter topic name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.yellowAccent),
            ),
          ),
          onChanged: (value) => newTopic = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newTopic != null && newTopic!.isNotEmpty) {
                try {
                  // Aggiungi il nuovo topic a Firestore
                  await FirebaseFirestore.instance
                      .collection('topics')
                      .doc(newTopic)
                      .set({
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // Aggiorna la lista locale dei topic
                  setState(() {
                    _topics.add(newTopic!);
                    _selectedTopic = newTopic;
                  });

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Topic "$newTopic" added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error adding topic: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding topic: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Add',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    bool isNewStep = step.content.isEmpty; // Verifica se è un nuovo step
    
    return Card(
      key: key,
      margin: EdgeInsets.only(bottom: 8),
      color: Color(0xFF282828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isNewStep ? Colors.yellowAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: Icon(
              Icons.drag_handle,
              color: Colors.white54,
              size: 20,
            ),
            title: Row(
              children: [
                Icon(
                  step.type == 'video' ? Icons.play_circle_outline : Icons.quiz_outlined,
                  color: Colors.yellowAccent,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.content.isEmpty ? 'New Step' : step.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.delete, color: Colors.white54, size: 18),
                  onPressed: () => _deleteStep(_sections.indexOf(_selectedSection!), index),
                ),
                SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedStepIndex = isExpanded ? null : index;
              });
            },
          ),
          
          // Contenuto espanso per la modifica
          if (isExpanded) ...[
            Divider(color: Colors.white.withOpacity(0.1)),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo di step
                  DropdownButtonFormField<String>(
                    value: step.type,
                    decoration: _inputDecoration('Step Type'),
                    dropdownColor: const Color(0xFF282828),
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
                      setState(() {
                        _selectedSection!.steps[index] = LevelStep(
                          type: value!,
                          content: step.content,
                          topic: step.topic,
                          choices: step.choices,
                          correctAnswer: step.correctAnswer,
                          explanation: step.explanation,
                          videoUrl: step.videoUrl,
                        );
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Campi specifici per tipo
                  if (step.type == 'video') ...[
                    // Campi per il video
                    TextFormField(
                      initialValue: step.content,
                      decoration: _inputDecoration('Video Title'),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection!.steps[index] = LevelStep(
                            type: step.type,
                            content: value,
                            topic: step.topic,
                            videoUrl: step.videoUrl,
                          );
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            child: _uploadProgress.containsKey(index)
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.yellowAccent),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      LinearProgressIndicator(
                                        value: _uploadProgress[index],
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.yellowAccent.withOpacity(0.3),
                                        ),
                                      ),
                                      Text(
                                        'Uploading ${(_uploadProgress[index]! * 100).toInt()}%',
                                        style: TextStyle(
                                          color: Colors.yellowAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ElevatedButton.icon(
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
                                  label: Text('Upload Video'),
                                  onPressed: () async {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.video,
                                      allowMultiple: false,
                                    );

                                    if (result != null) {
                                      final videoFile = File(result.files.single.path!);
                                      try {
                                        // Se c'è già un video, eliminalo prima
                                        if (step.videoUrl != null) {
                                          await _deleteVideoFromStorage(step.videoUrl!);
                                        }

                                        // Inizializza il progresso
                                        setState(() {
                                          _uploadProgress[index] = 0;
                                        });

                                        await _uploadVideo(
                                          videoFile,
                                          (String videoUrl) {
                                            if (mounted) {
                                              setState(() {
                                                _uploadProgress.remove(index);
                                                _selectedSection!.steps[index] = LevelStep(
                                                  type: 'video',
                                                  content: step.content,
                                                  videoUrl: videoUrl,
                                                  thumbnailUrl: null,
                                                  isShort: false,
                                                  topic: widget.course?.topic ?? '',
                                                );
                                              });
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Video uploaded successfully!')),
                                            );
                                          },
                                          (String error) {
                                            setState(() {
                                              _uploadProgress.remove(index);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $error'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          },
                                          // Aggiungi callback per il progresso
                                          (double progress) {
                                            if (mounted) {
                                              setState(() {
                                                _uploadProgress[index] = progress;
                                              });
                                            }
                                          },
                                        );
                                      } catch (e) {
                                        setState(() {
                                          _uploadProgress.remove(index);
                                        });
                                        print('Error during upload: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error during upload: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                          ),
                        ),
                        if (step.videoUrl != null) ...[
                          SizedBox(width: 16),
                          IconButton(
                            icon: Icon(Icons.play_circle_outline, color: Colors.yellowAccent),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: AspectRatio(
                                    aspectRatio: 9/16,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        color: Colors.black,
                                        child: VideoPlayer(
                                          step.videoUrl!,
                                          autoPlay: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ] else if (step.type == 'question') ...[
                    // Campi per la domanda
                    TextFormField(
                      initialValue: step.content,
                      decoration: _inputDecoration('Question'),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection!.steps[index] = LevelStep(
                            type: step.type,
                            content: value,
                            topic: step.topic,
                            choices: step.choices,
                            correctAnswer: step.correctAnswer,
                            explanation: step.explanation,
                          );
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: step.choices?.join(', '),
                      decoration: _inputDecoration('Options (comma separated)'),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection!.steps[index] = LevelStep(
                            type: step.type,
                            content: step.content,
                            topic: step.topic,
                            choices: value.split(',').map((e) => e.trim()).toList(),
                            correctAnswer: step.correctAnswer,
                            explanation: step.explanation,
                          );
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: step.correctAnswer,
                      decoration: _inputDecoration('Correct Answer'),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection!.steps[index] = LevelStep(
                            type: step.type,
                            content: step.content,
                            topic: step.topic,
                            choices: step.choices,
                            correctAnswer: value,
                            explanation: step.explanation,
                          );
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: step.explanation,
                      decoration: _inputDecoration('Explanation'),
                      style: TextStyle(color: Colors.white),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _selectedSection!.steps[index] = LevelStep(
                            type: step.type,
                            content: step.content,
                            topic: step.topic,
                            choices: step.choices,
                            correctAnswer: step.correctAnswer,
                            explanation: value,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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
        onTap: () {
          setState(() {
            // Aggiungi un nuovo step vuoto alla sezione corrente
            _selectedSection!.steps.add(LevelStep(
              type: 'question', // tipo predefinito
              content: '',
              topic: widget.course?.topic ?? '',
              choices: [],
            ));
            // Espandi automaticamente il nuovo step
            _expandedStepIndex = _selectedSection!.steps.length - 1;
          });
        },
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
    _course = widget.course;
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
      _isSubscriptionRequired = widget.course!.isSubscriptionRequired;

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
                            setState(() {
                              isUploading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Errore: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          (double progress) {
                            if (mounted) {
                              setState(() {
                                _uploadProgress[sectionIndex] = progress;
                              });
                            }
                          },
                        );
                      } catch (e) {
                        setState(() {
                          isUploading = false;
                        });
                        print('Errore durante l\'upload: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Errore durante l\'upload: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
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
                        decoration: _inputDecoration('Question'),
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
                  onPressed: () => _deleteStep(_sections.indexOf(_selectedSection!), stepIndex),
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

  void _deleteStep(int sectionIndex, int stepIndex) async {
    // Se è un video, elimina prima il file dallo storage
    final step = _selectedSection!.steps[stepIndex];
    if (step.type == 'video' && step.videoUrl != null) {
      await _deleteVideoFromStorage(step.videoUrl!);
    }

    setState(() {
      _selectedSection!.steps.removeAt(stepIndex);
      _expandedStepIndex = null;
    });
  }

  Future<void> _deleteVideoFromStorage(String videoUrl) async {
    try {
      // Estrai il nome del file dall'URL
      final fileName = videoUrl.split('%2F').last.split('?').first;
      // Crea il riferimento al file usando il percorso completo
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('course_videos')
          .child(fileName);
      
      await storageRef.delete();
      print('Video deleted successfully from storage');
    } catch (e) {
      print('Error deleting video from storage: $e');
      // Non lanciare l'errore per permettere comunque l'aggiornamento dell'UI
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final courseData = {
        'title': _courseTitle,
        'description': _courseDescription,
        'cost': _courseCost,
        'topic': _selectedTopic,
        'sections': _sections.map((s) => s.toMap()).toList(),
        'visible': true,
        'authorId': FirebaseAuth.instance.currentUser?.uid,
        'coverImageUrl': _coverImageUrl,
        'isSubscriptionRequired': _isSubscriptionRequired,
      };

      if (_isEditing && _course != null) {
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(_course!.id)
            .update(courseData);
      } else {
        await FirebaseFirestore.instance
            .collection('courses')
            .add(courseData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error saving course: $e');
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

  Future<void> _uploadVideo(
    File videoFile,
    Function(String) onSuccess,
    Function(String) onError,
    Function(double) onProgress,
  ) async {
    try {
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('course_videos')
          .child(fileName);

      final bytes = await videoFile.readAsBytes();
      
      final uploadTask = videoRef.putData(
        bytes,
        firebase_storage.SettableMetadata(contentType: 'video/mp4')
      );

      uploadTask.snapshotEvents.listen(
        (snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        },
        onError: (error) {
          print('Error during upload progress monitoring: $error');
          onError(error.toString());
        },
        cancelOnError: false,
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
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

class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const VideoPlayer(this.videoUrl, {this.autoPlay = false});

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
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
      autoPlay: widget.autoPlay,
      looping: false,
      aspectRatio: 9/16,
      autoInitialize: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null
        ? Chewie(controller: _chewieController!)
        : Center(
            child: CircularProgressIndicator(
              color: Colors.yellowAccent,
            ),
          );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
