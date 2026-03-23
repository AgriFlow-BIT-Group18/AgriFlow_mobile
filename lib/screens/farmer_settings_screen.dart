import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';

class FarmerSettingsScreen extends StatefulWidget {
  const FarmerSettingsScreen({super.key});

  @override
  State<FarmerSettingsScreen> createState() => _FarmerSettingsScreenState();
}

class _FarmerSettingsScreenState extends State<FarmerSettingsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final TranslationService _translationService = TranslationService();

  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initTranslation();
  }

  Future<void> _initTranslation() async {
    await _translationService.init();
    await _loadInitialData();
  }

  final List<String> _countries = [
    'Burkina Faso', 'Sénégal', 'Côte d\'Ivoire', 'Mali',
    'Ghana', 'Bénin', 'Nigéria', 'Togo',
  ];

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      setState(() {
        _userId = user['_id'];
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        String country = user['region'] ?? 'Burkina Faso';
        if (!_countries.contains(country)) country = 'Burkina Faso';
        _regionController.text = country;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.updateProfile(_userId!, {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'region': _regionController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_userId == null || _currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.updatePassword(
        _userId!,
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F7),
        appBar: AppBar(
          title: Text(_translationService.translate('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF2D6C50),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2D6C50),
            tabs: [
              Tab(text: _translationService.translate('profile')),
              Tab(text: _translationService.translate('security')),
              Tab(text: _translationService.translate('language')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(),
            _buildSecurityTab(),
            _buildLanguageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTab() {
    return _LanguageSelectorView(
      translationService: _translationService,
      onLanguageChanged: () => setState(() {}),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_translationService.translate('account_info'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildTextField(_translationService.translate('full_name'), _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_translationService.translate('phone_number'), _phoneController, Icons.phone_outlined),
            const SizedBox(height: 16),
            Text(_translationService.translate('country').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _countries.contains(_regionController.text) ? _regionController.text : 'Burkina Faso',
              decoration: _inputDecoration('', Icons.public_outlined),
              items: _countries.map((String country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: (val) => setState(() => _regionController.text = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6C50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_translationService.translate('save_changes'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_translationService.translate('change_password'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildTextField(_translationService.translate('current_password'), _currentPasswordController, Icons.lock_outline, isPassword: true),
          const SizedBox(height: 16),
          _buildTextField(_translationService.translate('new_password'), _newPasswordController, Icons.lock_reset, isPassword: true),
          const SizedBox(height: 16),
          _buildTextField(_translationService.translate('confirm_password'), _confirmPasswordController, Icons.check_circle_outline, isPassword: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_translationService.translate('update_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2D6C50)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D6C50)),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Field cannot be empty';
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF2D6C50)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6C50))),
    );
  }
}

class _LanguageSelectorView extends StatefulWidget {
  final TranslationService translationService;
  final VoidCallback onLanguageChanged;

  const _LanguageSelectorView({
    required this.translationService,
    required this.onLanguageChanged,
  });

  @override
  State<_LanguageSelectorView> createState() => _LanguageSelectorViewState();
}

class _LanguageSelectorViewState extends State<_LanguageSelectorView> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLocales = [];

  @override
  void initState() {
    super.initState();
    _filteredLocales = widget.translationService.supportedLocales;
  }

  void _filterLanguages(String query) {
    setState(() {
      _filteredLocales = widget.translationService.supportedLocales.where((locale) {
        final name = widget.translationService.getLanguageName(locale).toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A), // Dark theme as requested
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLanguages,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search language...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filteredLocales.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, index) {
                final locale = _filteredLocales[index];
                final isSelected = widget.translationService.currentLocale == locale;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Text(
                    widget.translationService.getLanguageFlag(locale),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    widget.translationService.getLanguageName(locale),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.shade700,
                        width: 2,
                      ),
                      color: isSelected ? const Color(0xFF2D6C50) : Colors.transparent,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 16) 
                      : null,
                  ),
                  onTap: () async {
                    await widget.translationService.setLocale(locale);
                    widget.onLanguageChanged();
                    setState(() {});
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6C50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Sauvegarder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
