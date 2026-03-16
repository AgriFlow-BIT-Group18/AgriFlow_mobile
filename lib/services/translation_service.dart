import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  String _currentLocale = 'en';
  final List<String> supportedLocales = ['en', 'fr', 'pt', 'es'];

  final Map<String, Map<String, String>> _translations = {
    'en': {
      'flag': '🇺🇸',
      'settings': 'Settings',
      'profile': 'Profile',
      'security': 'Security',
      'language': 'Language',
      'save_changes': 'Save Changes',
      'update_password': 'Update Password',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'region': 'Region',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'account_info': 'Account Information',
      'change_password': 'Change Password',
      'select_language': 'Select Language',
      'my_profile': 'My Profile',
      'sign_out': 'Sign Out',
      'email': 'Email',
      'country': 'Country',
    },
    'fr': {
      'flag': '🇫🇷',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'security': 'Sécurité',
      'language': 'Langue',
      'save_changes': 'Enregistrer',
      'update_password': 'Modifier le mot de passe',
      'full_name': 'Nom Complet',
      'phone_number': 'Numéro de Téléphone',
      'region': 'Région',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'confirm_password': 'Confirmez le mot de passe',
      'account_info': 'Informations du Compte',
      'change_password': 'Changer le mot de passe',
      'select_language': 'Choisir la Langue',
      'my_profile': 'Mon Profil',
      'sign_out': 'Déconnexion',
      'email': 'Email',
      'country': 'Pays',
    },
    'pt': {
      'flag': '🇵🇹',
      'settings': 'Configurações',
      'profile': 'Perfil',
      'security': 'Segurança',
      'language': 'Idioma',
      'country': 'País',
    },
    'es': {
      'flag': '🇪🇸',
      'settings': 'Ajustes',
      'profile': 'Perfil',
      'security': 'Seguridad',
      'language': 'Idioma',
      'country': 'País',
    },
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('language') ?? 'en';
  }

  String translate(String key) {
    return _translations[_currentLocale]?[key] ?? _translations['en']?[key] ?? key;
  }

  String get currentLocale => _currentLocale;

  Future<void> setLocale(String locale) async {
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale);
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'fr': return 'Français';
      case 'pt': return 'Português';
      case 'es': return 'Español';
      default: return code.toUpperCase();
    }
  }

  String getLanguageFlag(String code) {
    return _translations[code]?['flag'] ?? '🌐';
  }
}
