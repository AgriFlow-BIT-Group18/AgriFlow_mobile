import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKey = const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''); // Must be passed during build
  static const String _model = 'llama-3.3-70b-versatile';

  static const String _systemPrompt = '''
AgriFlow Neural: Primary AI brain. Professional, concise, premium. 
(FR: Cerveau IA principal. Professionnel, concis, haut de gamme.)

### STRICT LANGUAGE RULES:
1. DETECT the language of the user's latest message.
2. RESPOND EXCLUSIVELY in that same language (French or English).
3. NEVER mix languages in a single response.
4. If the user writes in French, every word you speak must be French.
5. If the user writes in English, every word you speak must be English.

### CONTEXT & RULES:
- CURRENCY: Always use "FCFA".
- PROJECT: AgriFlow is a digital system for agricultural input distribution in West Africa.
- TONE: Professional, efficient, and direct.
''';

  Future<String> getChatCompletion(List<Map<String, String>> messages) async {
    try {
      final List<Map<String, String>> fullMessages = [
        {'role': 'system', 'content': _systemPrompt},
        ...messages,
      ];

      print('AI Request: Sending ${messages.length} messages to Groq...');
      
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': fullMessages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      print('AI Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('AI Response Success: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
        return content;
      } else {
        print('AI Response Error: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to connect to Groq AI (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('AI Catch Error: $e');
      throw Exception('AI Error: ${e.toString()}');
    }
  }
}
