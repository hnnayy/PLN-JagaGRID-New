import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/services/user_service.dart';

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
  final _levelController = TextEditingController();
  final _addedDateController = TextEditingController();
  final _chatIdTelegramController = TextEditingController();
  final UserService _userService = UserService();

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
      final docId = prefs.getString('session_id');

      if (docId != null) {
        _userDocId = docId;

        final user = await _userService.getUserById(docId);
        if (user != null) {
          setState(() {
            _fullNameController.text = user.name;
            _usernameController.text = user.username.replaceFirst('@', '');
            _telegramUsernameController.text = user.usernameTelegram.replaceFirst('@', '');
            _unitController.text = user.unit;
            _levelController.text = user.level == 1 ? 'Unit Induk' : 'Unit Layanan';
            _addedDateController.text = user.added;
            _chatIdTelegramController.text = user.chatIdTelegram;
            _headerName = user.name;
            _isLoading = false;
          });

          await prefs.setString('session_name', user.name);
          await prefs.setString('session_username', user.username);
          await prefs.setString('session_username_telegram', user.usernameTelegram);
          await prefs.setString('session_unit', user.unit);
          await prefs.setInt('session_level', user.level);
          await prefs.setString('session_added', user.added);
          await prefs.setString('session_chat_id_telegram', user.chatIdTelegram);
          await prefs.setInt('session_status', user.status);
        } else {
          await _loadFromSharedPreferences();
        }
      } else {
        await _loadFromSharedPreferences();
      }

      _fullNameController.addListener(_autoSaveProfile);
      _usernameController.addListener(_autoSaveProfile);
      _telegramUsernameController.addListener(_autoSaveProfile);
      _chatIdTelegramController.addListener(_autoSaveProfile);
    } catch (e) {
      debugPrint('Error loading session: $e');
      await _loadFromSharedPreferences();
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('session_name') ?? '';
      _usernameController.text = (prefs.getString('session_username') ?? '').replaceFirst('@', '');
      _telegramUsernameController.text = (prefs.getString('session_username_telegram') ?? '').replaceFirst('@', '');
      _unitController.text = prefs.getString('session_unit') ?? '';
      _levelController.text = (prefs.getInt('session_level') ?? 2) == 1 ? 'Unit Induk' : 'Unit Layanan';
      _addedDateController.text = prefs.getString('session_added') ?? '';
      _chatIdTelegramController.text = prefs.getString('session_chat_id_telegram') ?? '';
      _headerName = prefs.getString('session_name') ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_autoSaveProfile);
    _usernameController.removeListener(_autoSaveProfile);
    _telegramUsernameController.removeListener(_autoSaveProfile);
    _chatIdTelegramController.removeListener(_autoSaveProfile);
    _fullNameController.dispose();
    _usernameController.dispose();
    _telegramUsernameController.dispose();
    _unitController.dispose();
    _levelController.dispose();
    _addedDateController.dispose();
    _chatIdTelegramController.dispose();
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
                  _buildEditableField(label: 'Full Name', controller: _fullNameController),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Username', controller: _usernameController),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Telegram Username', controller: _telegramUsernameController),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Chat ID Telegram', controller: _chatIdTelegramController, readOnly: true),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Unit', controller: _unitController, readOnly: true),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Level', controller: _levelController, readOnly: true),
                  const SizedBox(height: 20),
                  _buildEditableField(label: 'Added Date', controller: _addedDateController, readOnly: true),
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

      if (_userDocId == null) {
        _showErrorAlert("User document not found. Cannot save changes.");
        return;
      }

      // Only update editable fields
      final updateData = {
        'name': _fullNameController.text.trim(),
        'username': "@${_usernameController.text.trim()}",
        'username_telegram': _telegramUsernameController.text.isNotEmpty
            ? "@${_telegramUsernameController.text.trim()}"
            : "",
        'updated_at': DateTime.now(),
      };

      await _userService.updateUserPartial(_userDocId!, updateData);

      await prefs.setString('session_name', updateData['name'] as String);
      await prefs.setString('session_username', updateData['username'] as String);
      await prefs.setString('session_username_telegram', updateData['username_telegram'] as String);

      debugPrint("Profile saved: $updateData");

      _showSuccessAlert();
    } catch (e) {
      debugPrint("Save error: $e");
      _showErrorAlert("Failed to save profile: $e");
    }
  }

  void _autoSaveProfile() async {
    if (_userDocId == null) return;

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_userDocId == null) return;

      final updateData = {
        'name': _fullNameController.text.trim(),
        'username': "@${_usernameController.text.trim()}",
        'username_telegram': _telegramUsernameController.text.isNotEmpty
            ? "@${_telegramUsernameController.text.trim()}"
            : "",
        'updated_at': DateTime.now(),
      };

      await _userService.updateUserPartial(_userDocId!, updateData);
      debugPrint("Auto-saved profile");
    } catch (e) {
      debugPrint("Auto-save error: $e");
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5D6F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Berhasil!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5D6F),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Profile berhasil disimpan",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Gagal!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: (value) {
            if ((value == null || value.isEmpty) &&
                label != 'Telegram Username' && label != 'Chat ID Telegram') {
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
              borderSide: const BorderSide(color: Color(0xFF125E72), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}