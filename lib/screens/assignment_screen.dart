import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/level.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';

class AssignmentScreen extends StatefulWidget {
  final LevelStep step;
  final String courseId;

  const AssignmentScreen({
    Key? key,
    required this.step,
    required this.courseId,
  }) : super(key: key);

  @override
  _AssignmentScreenState createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadedFileName;
  String? _uploadedFileUrl;
  String? _fileType;
  int? _fileSize;
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioReady = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _initAudio();
    _loadExistingSubmission();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('success_sound.mp3'));
      _isAudioReady = true;
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> _loadExistingSubmission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final submission = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('assignments')
          .doc(user.uid)
          .get();

      if (submission.exists && submission.data()?['stepId'] == widget.step.content) {
        setState(() {
          _uploadedFileName = submission.data()?['fileName'];
          _uploadedFileUrl = submission.data()?['fileUrl'];
          _fileType = submission.data()?['fileType'];
          _fileSize = submission.data()?['fileSize'];
        });
      }
    } catch (e) {
      print('Error loading submission: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Delete previous file if it exists
      if (_uploadedFileUrl != null) {
        try {
          final previousFileRef = FirebaseStorage.instance.refFromURL(_uploadedFileUrl!);
          await previousFileRef.delete();
        } catch (e) {
          print('Error deleting previous file: $e');
        }
      }

      File? file;
      String? fileName;
      
      // Show bottom sheet with options
      final String? choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Colors.yellowAccent.withOpacity(0.8),
                    ),
                  ),
                  title: const Text(
                    'Photo from gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'photo'),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Colors.yellowAccent.withOpacity(0.8),
                    ),
                  ),
                  title: const Text(
                    'Video from gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.yellowAccent.withOpacity(0.8),
                    ),
                  ),
                  title: const Text(
                    'PDF document',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      final picker = ImagePicker();
      
      switch (choice) {
        case 'photo':
          final XFile? pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
            maxHeight: 1920,
            maxWidth: 1080,
            imageQuality: 85,
          );
          if (pickedFile == null) return;
          file = File(pickedFile.path);
          fileName = path.basename(pickedFile.path);
          break;
          
        case 'video':
          final XFile? pickedFile = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          if (pickedFile == null) return;
          file = File(pickedFile.path);
          fileName = path.basename(pickedFile.path);
          break;
          
        case 'pdf':
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) return;
          file = File(result.files.single.path!);
          fileName = result.files.single.name;
          break;
      }

      if (file == null || fileName == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final fileSize = await file.length();
      final fileExtension = path.extension(fileName).toLowerCase();

      // Validate file size (max 100MB)
      if (fileSize > 100 * 1024 * 1024) {
        _showErrorSnackBar('File too large. Maximum size is 100MB');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('assignments/${widget.courseId}/${widget.step.content}/${user.uid}/$fileName');

      final uploadTask = storageRef.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('assignments')
            .doc(user.uid)
            .set({
          'stepId': widget.step.content,
          'fileName': fileName,
          'fileUrl': downloadUrl,
          'fileType': fileExtension,
          'fileSize': fileSize,
          'submissionDate': FieldValue.serverTimestamp(),
          'status': 'submitted',
          'userId': user.uid,
        });

        setState(() {
          _isUploading = false;
          _uploadedFileName = fileName;
          _uploadedFileUrl = downloadUrl;
          _fileType = fileExtension;
          _fileSize = fileSize;
        });

        if (_isAudioReady) {
          await _audioPlayer.resume();
        }

        _showSuccessSnackBar('Assignment submitted successfully!');
      });
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorSnackBar('Error uploading file: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.withOpacity(0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red.withOpacity(0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 40,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASSIGNMENT',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.step.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description Section
                    if (widget.step.explanation != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                          child: Stack(
                            children: [
                              Text(
                                widget.step.explanation!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                maxLines: _isDescriptionExpanded ? null : 2,
                                overflow: _isDescriptionExpanded ? null : TextOverflow.fade,
                              ),
                              if (!_isDescriptionExpanded)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFF121212).withOpacity(0),
                                          const Color(0xFF121212),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (!_isDescriptionExpanded)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellowAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Read more',
                                          style: TextStyle(
                                            color: Colors.yellowAccent.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.yellowAccent.withOpacity(0.8),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Upload Section
                    Container(
                      margin: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Current submission status
                          if (_uploadedFileName != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Current Submission',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _uploadedFileName!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_fileSize != null)
                                          Text(
                                            _formatFileSize(_fileSize!),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Upload area
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.yellowAccent.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isUploading ? null : _pickAndUploadFile,
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: _isUploading
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 64,
                                                  height: 64,
                                                  child: CircularProgressIndicator(
                                                    value: _uploadProgress,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.yellowAccent.withOpacity(0.8),
                                                    ),
                                                    strokeWidth: 3,
                                                  ),
                                                ),
                                                Text(
                                                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Uploading...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.yellowAccent.withOpacity(0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _uploadedFileName != null
                                                    ? Icons.upload_rounded
                                                    : Icons.cloud_upload_outlined,
                                                color: Colors.yellowAccent.withOpacity(0.8),
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _uploadedFileName != null
                                                  ? 'Replace file'
                                                  : 'Upload assignment',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'PDF • Images • Video (max 100MB)',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 