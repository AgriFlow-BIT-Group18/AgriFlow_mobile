import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/main_layout.dart';
import '../services/ai_service.dart';

import '../services/translation_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final TranslationService _ts = TranslationService();
  
  final SpeechService _speech = SpeechService();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isLoading = false;
  bool _isTranscribing = false;
  late final List<Map<String, String>> _messages;
  String? _currentTtsLanguage;
  
  // Animation for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mapping locale courte -> locale TTS complète
  static const Map<String, String> _ttsLocaleMap = {
    'en': 'en-US',
    'fr': 'fr-FR',
    'pt': 'pt-BR',
    'es': 'es-ES',
  };

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'role': 'assistant',
        'content': _ts.translate('ai_welcome_msg')
      },
    ];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
  }

  void _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    
    if (kIsWeb) {
      // Force fetching voices on Web to avoid [object SpeechSynthesisErrorEvent]
      await _tts.getVoices;
    }

    final ttsLocale = _ttsLocaleMap[_ts.currentLocale] ?? 'en-US';
    await _tts.setLanguage(ttsLocale);
  }



  void _listen() async {
    await _tts.stop();

    if (!_isListening) {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      await _speech.startRecording();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isListening = false;
        _isTranscribing = true;
      });
      
      final text = await _speech.stopRecording();
      
      if (mounted) {
        setState(() => _isTranscribing = false);
        if (text != null && text.isNotEmpty) {
          _inputController.text = text;
          _handleSend();
        } else if (text == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_ts.currentLocale == 'fr' 
                  ? 'Erreur de transcription. Réessayez.' 
                  : 'Transcription error. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
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

    // Stop listening so it doesn't overwrite the cleared text
    if (_isListening) {
      await _speech.stopRecording();
      setState(() => _isListening = false);
    }

    // Capturer le texte et vider immédiatement le champ
    _inputController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m['role']!,
        'content': m['content']!,
      }).toList();

      final currentLocale = _ts.currentLocale;
      final response = await _aiService.getChatCompletion(history);

      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
      
      // Play TTS audio
      final String ttsLang = _ttsLocaleMap[currentLocale] ?? 'en-US';
      
      if (_currentTtsLanguage != ttsLang) {
        await _tts.setLanguage(ttsLang);
        _currentTtsLanguage = ttsLang;
      }
      await _tts.speak(response);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _ts.currentLocale == 'fr'
              ? 'Désolé, une erreur est survenue : ${e.toString()}. Vérifiez votre connexion.'
              : 'Sorry, I encountered an error: ${e.toString()}. Please check your connection.'
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF2D6A4F)),
            onPressed: () {
              // Arrêter le STT en cours
              if (_isListening) {
                _speech.stopRecording();
              }
              // Arrêter le TTS en cours
              _tts.stop();
              // Vider le champ de texte
              _inputController.clear();
              setState(() {
                _isListening = false;
                _isLoading = false;
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': _ts.translate('ai_welcome_msg')
                });
              });
            },
            tooltip: _ts.currentLocale == 'fr' ? 'Effacer la conversation' : 'Clear Conversation',
          ),
        ],
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
                                    hintText: _isTranscribing 
                                        ? (_ts.currentLocale == 'fr' ? 'Transcription...' : 'Transcribing...')
                                        : _ts.translate('ai_input_hint'),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  enabled: !_isLoading && !_isTranscribing,
                                ),
                              ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                onPressed: _listen,
                                icon: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (_isListening)
                                          Container(
                                            width: 24 * _pulseAnimation.value,
                                            height: 24 * _pulseAnimation.value,
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Icon(
                                          _isListening ? Icons.mic : Icons.mic_none,
                                          color: _isListening 
                                              ? Colors.red 
                                              : const Color(0xFF2D6A4F).withValues(alpha: 0.6),
                                        ),
                                      ],
                                    );
                                  },
                                ),
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
