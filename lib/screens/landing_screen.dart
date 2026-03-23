import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// Modèle de langue
class _Language {
  final String code;
  final String name;
  final String flag;
  const _Language(this.code, this.name, this.flag);
}

const _languages = [
  _Language('fr', 'Français', '🇫🇷'),
  _Language('en', 'English', '🇬🇧'),
  _Language('es', 'Español', '🇪🇸'),
  _Language('pt', 'Português', '🇵🇹'),
];

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TranslationService _ts = TranslationService();

  _Language get _currentLang =>
      _languages.firstWhere((l) => l.code == _ts.currentLocale,
          orElse: () => _languages[0]);

  void _changeLanguage(String locale) async {
    await _ts.setLocale(locale);
    if (mounted) setState(() {});
  }

  void _showLanguagePicker() {
    final TextEditingController searchCtrl = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _languages
              .where((l) =>
                  l.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  l.code.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Search field
                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setModalState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une langue...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Language list
                ...filtered.map((lang) {
                  final isSelected = lang.code == _ts.currentLocale;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 26)),
                    title: Text(
                      lang.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D6A4F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          )
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    hoverColor: Colors.white.withValues(alpha: 0.1),
                    onTap: () {
                      _changeLanguage(lang.code);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 12),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image d'arrière-plan (identique au web)
          Image.asset(
            'assets/images/hero_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Dégradé superposé sombre (comme bg-sidebar)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1B4332).withValues(alpha: 0.6),
                  const Color(0xFF1B4332).withValues(alpha: 0.2),
                  const Color(0xFF1B4332),
                ],
              ),
            ),
          ),
          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language Selector (drapeau + code + chevron)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: GestureDetector(
                        onTap: _showLanguagePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_currentLang.flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Text(
                                _currentLang.code.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Logo Section
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AgriFlow',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _ts.translate('welcome_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Action Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2D6A4F),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 10,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: Text(
                          _ts.translate('get_started'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _ts.translate('have_account'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
