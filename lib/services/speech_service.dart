import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SpeechService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPath;

  Future<void> startRecording() async {
    try {
      debugPrint('SpeechService: Checking permissions...');
      if (await _audioRecorder.hasPermission()) {
        final config = RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
        );

        if (kIsWeb) {
          debugPrint('SpeechService: Starting recording (Web)...');
          await _audioRecorder.start(config, path: '');
        } else {
          final directory = await getTemporaryDirectory();
          _currentPath = '${directory.path}/speech_to_text.m4a';
          debugPrint('SpeechService: Starting recording (Mobile) at $_currentPath');
          await _audioRecorder.start(config, path: _currentPath!);
        }
      } else {
        debugPrint('SpeechService: Microphone permission denied');
      }
    } catch (e) {
      debugPrint('SpeechService: Error starting recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      debugPrint('SpeechService: Stopping recording...');
      final path = await _audioRecorder.stop();
      debugPrint('SpeechService: Recording stopped, path/url: $path');
      
      // Basic validation: path should not be null
      if (path != null) {
        return await _transcribeAudio(path);
      }
    } catch (e) {
      debugPrint('SpeechService: Error stopping recording: $e');
    }
    return null;
  }

  Future<String?> _transcribeAudio(String path) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) {
      debugPrint('SpeechService: API Key NOT FOUND');
      return 'Error: API Key not found';
    }

    debugPrint('SpeechService: Sending to Groq Whisper...');
    final url = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
    
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = 'whisper-large-v3-turbo';

      if (kIsWeb) {
        debugPrint('SpeechService: Fetching blob bytes from $path');
        final response = await http.get(Uri.parse(path));
        final bytes = response.bodyBytes;
        debugPrint('SpeechService: Blob size: ${bytes.length} bytes');
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'speech.webm',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final text = data['text'] as String?;
        debugPrint('SpeechService: Transcription successful: $text');
        return text;
      } else {
        debugPrint('Groq Error: $responseBody');
        // Handle specific case where audio might be too short or invalid
        return null;
      }
    } catch (e) {
      debugPrint('SpeechService: Transcription exception: $e');
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
