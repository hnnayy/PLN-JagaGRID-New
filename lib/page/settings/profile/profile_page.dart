import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/models/profile.dart';
import 'package:flutter_application_2/services/profile_service.dart';

String? _userDocId;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _telegramUsernameController = TextEditingController();
  final _unitController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  String _headerName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docId = prefs.getString('session_docId');

      if (docId != null) {
        _userDocId = docId;

        final profile = await _profileService.getProfile(docId);
        if (profile != null) {
          setState(() {
            _fullNameController.text = profile.name;
            _usernameController.text = profile.username.replaceFirst('@', '');
            _telegramUsernameController.text =
                profile.telegramUsername.replaceFirst('@', '');
            _unitController.text = profile.unit;
            _headerName = profile.name;
            _isLoading = false;
          });

          await prefs.setString('session_name', profile.name);
          await prefs.setString('session_username', profile.username);
          await prefs.setString(
              'session_telegram_username', profile.telegramUsername);
          await prefs.setString('session_unit', profile.unit);
        } else {
          await _loadFromSharedPreferences();
        }
      } else {
        await _loadFromSharedPreferences();
      }

      _fullNameController.addListener(_autoSaveProfile);
      _usernameController.addListener(_autoSaveProfile);
      _telegramUsernameController.addListener(_autoSaveProfile);
    } catch (e) {
      debugPrint('Error loading session: $e');
      await _loadFromSharedPreferences();
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('session_name') ?? '';
      _usernameController.text =
          (prefs.getString('session_username') ?? '').replaceFirst('@', '');
      _telegramUsernameController.text =
          (prefs.getString('session_telegram_username') ?? '')
              .replaceFirst('@', '');
      _unitController.text = prefs.getString('session_unit') ?? '';
      _headerName = prefs.getString('session_name') ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_autoSaveProfile);
    _usernameController.removeListener(_autoSaveProfile);
    _telegramUsernameController.removeListener(_autoSaveProfile);
    _fullNameController.dispose();
    _usernameController.dispose();
    _telegramUsernameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF125E72),
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildProfileForm(),
              ),
            ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditableField(
                      label: 'Full Name', controller: _fullNameController),
                  const SizedBox(height: 20),
                  _buildEditableField(
                      label: 'Username', controller: _usernameController),
                  const SizedBox(height: 20),
                  _buildEditableField(
                      label: 'Telegram Username',
                      controller: _telegramUsernameController),
                  const SizedBox(height: 20),
                  _buildEditableField(
                      label: 'Unit',
                      controller: _unitController,
                      readOnly: true),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            _headerName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF125E72),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _headerName = _fullNameController.text);

      final profile = Profile(
        id: _userDocId ?? '',
        name: _fullNameController.text.trim(),
        username: "@${_usernameController.text.trim()}",
        telegramUsername: _telegramUsernameController.text.isNotEmpty
            ? "@${_telegramUsernameController.text.trim()}"
            : "",
        unit: _unitController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_userDocId == null) {
        final newDocId = await _profileService.addProfile(profile);
        _userDocId = newDocId;
        await prefs.setString('session_docId', newDocId);
      } else {
        await _profileService.updateProfile(profile);
      }

      await prefs.setString('session_name', profile.name);
      await prefs.setString('session_username', profile.username);
      await prefs.setString('session_telegram_username', profile.telegramUsername);
      await prefs.setString('session_unit', profile.unit);

      debugPrint("Profile saved: ${profile.toMap()}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _autoSaveProfile() async {
    if (_userDocId == null) return;

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final profile = Profile(
        id: _userDocId!,
        name: _fullNameController.text.trim(),
        username: "@${_usernameController.text.trim()}",
        telegramUsername: _telegramUsernameController.text.isNotEmpty
            ? "@${_telegramUsernameController.text.trim()}"
            : "",
        unit: _unitController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(profile);
      debugPrint("Auto-saved profile");
    } catch (e) {
      debugPrint("Auto-save error: $e");
    }
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: (value) {
            if ((value == null || value.isEmpty) &&
                label != 'Telegram Username') {
              return 'Please enter $label';
            }
            if (label == 'Username' && value!.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (label == 'Full Name' && value!.length < 2) {
              return 'Full name must be at least 2 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF125E72), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
