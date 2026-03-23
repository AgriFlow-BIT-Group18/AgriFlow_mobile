import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/main_layout.dart';
import '../services/ai_service.dart';

import '../services/translation_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final TranslationService _ts = TranslationService();
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;
  
  late final List<Map<String, String>> _messages;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'role': 'assistant',
        'content': _ts.translate('ai_welcome_msg')
      },
    ];
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _listen() async {
    // Stop toute lecture en cours avant d'écouter
    await _tts.stop();

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        
        // Find the best locale matching the current app language
        var locales = await _speech.locales();
        String currentLang = _ts.currentLocale;
        var targetLocale = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith(currentLang.toLowerCase()), 
            orElse: () => locales.isNotEmpty ? locales.first : stt.LocaleName('en_US', 'English')
        );

        _speech.listen(
          onResult: (val) => setState(() {
            _inputController.text = val.recognizedWords;
          }),
          localeId: targetLocale.localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _inputController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m['role']!,
        'content': m['content']!,
      }).toList();

      final response = await _aiService.getChatCompletion(history);

      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
      
      // Play TTS audio
      await _tts.setLanguage(_ts.currentLocale);
      await _tts.speak(response);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: ${e.toString()}. Please check your connection and try again.'
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _tts.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6), // background-light
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2D6A4F),
          ), // primary
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ts.translate('ai_assistant_title'),
                  style: const TextStyle(
                    color: Color(0xFF0F172A), // slate-900
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green, // outline from tailwind bg-green-500
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _ts.translate('online_expert'),
                      style: const TextStyle(
                        color: Color(0xFF64748B), // slate-500
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                  
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  
                  if (isUser) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildUserMessage(message['content']!, 'Just now'),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildAiMessage(message['content']!, 'Just now'),
                    );
                  }
                },
              ),
            ),

            // Interaction Area (Footer)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suggestion Chips (only show if not loading and no user messages yet)
                  if (_messages.length <= 1 && !_isLoading)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          _buildSuggestionChip(_ts.translate('ai_suggestion_1')),
                          const SizedBox(width: 8),
                          _buildSuggestionChip(_ts.translate('ai_suggestion_2')),
                          const SizedBox(width: 8),
                          _buildSuggestionChip(_ts.translate('ai_suggestion_3')),
                        ],
                      ),
                    ),

                  // Input Box
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // slate-100
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  onSubmitted: (_) => _handleSend(),
                                  decoration: InputDecoration(
                                    hintText: _ts.translate('ai_input_hint'),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening 
                                        ? Colors.red 
                                        : const Color(0xFF2D6A4F).withValues(alpha: 0.6),
                                  ),
                                  onPressed: _speechEnabled ? _listen : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('La reconnaissance vocale n\'est pas disponible.'))
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                          onPressed: _handleSend,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, _ts.translate('home'), Icons.home_outlined, 0),
                  _buildNavItem(context, _ts.translate('catalogue'), Icons.grid_view_outlined, 1),
                  _buildNavItem(context, _ts.translate('orders'), Icons.receipt_long_outlined, 2),
                  _buildNavItem(context, _ts.translate('profile'), Icons.person_outline, 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2D6A4F),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            _ts.translate('thinking'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiMessage(String text, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2D6A4F),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'AGRIFLOW AI • ${time.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8), // slate-400
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildUserMessage(String text, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'YOU • ${time.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade200,
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage('https://via.placeholder.com/150'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _inputController.text = label;
        _handleSend();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2D6A4F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData icon, int index) {
    const color = Color(0xFF94A3B8);
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
