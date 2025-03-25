import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoCompressionService {
  static final VideoCompressionService _instance = VideoCompressionService._internal();
  factory VideoCompressionService() => _instance;
  VideoCompressionService._internal();

  final String baseUrl = 'http://localhost:3000'; // Your server URL

  Future<File?> compressVideo(File videoFile, {
    int quality = 28, // 0-51, lower is better quality
    int maxWidth = 1080, // Changed to 1080 for vertical video (9:16)
    int maxHeight = 1920, // Changed to 1920 for vertical video (9:16)
    int fps = 30, // Target FPS
    int audioBitrate = 128, // Audio bitrate in kbps
    Function(double)? onProgress,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/video/compress'),
      );

      // Add video file
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
        ),
      );

      // Add compression parameters
      request.fields.addAll({
        'quality': quality.toString(),
        'maxWidth': maxWidth.toString(),
        'maxHeight': maxHeight.toString(),
        'fps': fps.toString(),
        'audioBitrate': audioBitrate.toString(),
      });

      print('Compressing video with parameters:');
      print('maxWidth: $maxWidth');
      print('maxHeight: $maxHeight');
      print('quality: $quality');
      print('fps: $fps');
      print('audioBitrate: $audioBitrate');

      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        // Get temporary directory for output
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
        
        // Save the compressed video
        final file = File(outputPath);
        await file.writeAsBytes(await response.stream.toBytes());
        
        return file;
      } else {
        print('Server returned error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error compressing video: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getVideoInfo(File videoFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/video/info'),
      );

      // Add video file
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
        ),
      );

      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return json.decode(responseData);
      } else {
        print('Server returned error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error getting video info: $e');
      return {};
    }
  }
} 