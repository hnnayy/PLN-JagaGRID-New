import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/services/user_service.dart';

String? _userDocId;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _telegramUsernameController = TextEditingController();
  final _unitController = TextEditingController();
  final _levelController = TextEditingController();
  final _addedDateController = TextEditingController();
  final UserService _userService = UserService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _headerName = '';
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _primary = Color(0xFF0D5068);
  static const Color _primaryLight = Color(0xFF1A7A96);
  static const Color _accent = Color(0xFF00C9A7);
  static const Color _bg = Color(0xFFF2F6F8);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadSession();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.removeListener(_autoSaveProfile);
    _usernameController.removeListener(_autoSaveProfile);
    _telegramUsernameController.removeListener(_autoSaveProfile);
    _fullNameController.dispose();
    _usernameController.dispose();
    _telegramUsernameController.dispose();
    _unitController.dispose();
    _levelController.dispose();
    _addedDateController.dispose();
    super.dispose();
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
            _usernameController.text =
                user.username.replaceFirst('@', '');
            _telegramUsernameController.text =
                user.usernameTelegram.replaceFirst('@', '');
            _unitController.text = user.unit;
            _levelController.text =
                user.level == 1 ? 'Unit Induk' : 'Unit Layanan';
            _addedDateController.text = user.added;
            _headerName = user.name;
            _isLoading = false;
          });
          await prefs.setString('session_name', user.name);
          await prefs.setString('session_username', user.username);
          await prefs.setString(
              'session_username_telegram', user.usernameTelegram);
          await prefs.setString('session_unit', user.unit);
          await prefs.setInt('session_level', user.level);
          await prefs.setString('session_added', user.added);
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
      _animController.forward();
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
          (prefs.getString('session_username') ?? '')
              .replaceFirst('@', '');
      _telegramUsernameController.text =
          (prefs.getString('session_username_telegram') ?? '')
              .replaceFirst('@', '');
      _unitController.text = prefs.getString('session_unit') ?? '';
      _levelController.text =
          (prefs.getInt('session_level') ?? 2) == 1
              ? 'Unit Induk'
              : 'Unit Layanan';
      _addedDateController.text =
          prefs.getString('session_added') ?? '';
      _headerName = prefs.getString('session_name') ?? '';
      _isLoading = false;
    });
    _animController.forward();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _headerName = _fullNameController.text);

      if (_userDocId == null) {
        _showErrorAlert('User document not found. Cannot save changes.');
        return;
      }

      final updateData = {
        'name': _fullNameController.text.trim(),
        'username': '@${_usernameController.text.trim()}',
        'username_telegram': _telegramUsernameController.text.isNotEmpty
            ? '@${_telegramUsernameController.text.trim()}'
            : '',
        'updated_at': DateTime.now(),
      };

      await _userService.updateUserPartial(_userDocId!, updateData);
      await prefs.setString('session_name', updateData['name'] as String);
      await prefs.setString(
          'session_username', updateData['username'] as String);
      await prefs.setString('session_username_telegram',
          updateData['username_telegram'] as String);

      _showSuccessAlert();
    } catch (e) {
      debugPrint('Save error: $e');
      _showErrorAlert('Failed to save profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _autoSaveProfile() async {
    if (_userDocId == null) return;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_userDocId == null) return;
      final updateData = {
        'name': _fullNameController.text.trim(),
        'username': '@${_usernameController.text.trim()}',
        'username_telegram': _telegramUsernameController.text.isNotEmpty
            ? '@${_telegramUsernameController.text.trim()}'
            : '',
        'updated_at': DateTime.now(),
      };
      await _userService.updateUserPartial(_userDocId!, updateData);
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }

  // ──────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _sectionLabel('Informasi Akun'),
                            const SizedBox(height: 12),
                            _buildCard([
                              _buildField(
                                label: 'Nama Lengkap',
                                controller: _fullNameController,
                                icon: Icons.person_outline,
                              ),
                              _divider(),
                              _buildField(
                                label: 'Username',
                                controller: _usernameController,
                                icon: Icons.alternate_email,
                                prefix: '@',
                              ),
                              _divider(),
                              _buildField(
                                label: 'Telegram',
                                controller: _telegramUsernameController,
                                icon: Icons.send_outlined,
                                prefix: '@',
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _sectionLabel('Informasi Unit'),
                            const SizedBox(height: 12),
                            _buildCard([
                              _buildField(
                                label: 'Unit',
                                controller: _unitController,
                                icon: Icons.business_outlined,
                                readOnly: true,
                              ),
                              _divider(),
                              _buildField(
                                label: 'Level',
                                controller: _levelController,
                                icon: Icons.layers_outlined,
                                readOnly: true,
                              ),
                              _divider(),
                              _buildField(
                                label: 'Tanggal Bergabung',
                                controller: _addedDateController,
                                icon: Icons.calendar_today_outlined,
                                readOnly: true,
                              ),
                            ]),
                            const SizedBox(height: 32),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Sliver AppBar dengan header avatar overlap ──
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Profil Saya',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Avatar + name
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: _accent.withOpacity(0.25),
                      child: Text(
                        _headerName.isNotEmpty
                            ? _headerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _headerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _levelController.text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ──
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Card wrapper ──
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
        indent: 52,
      );

  // ── Field ──
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: (value) {
          if ((value == null || value.isEmpty) && label != 'Telegram') {
            return 'Wajib diisi';
          }
          if (label == 'Username' && (value?.length ?? 0) < 3) {
            return 'Minimal 3 karakter';
          }
          if (label == 'Nama Lengkap' && (value?.length ?? 0) < 2) {
            return 'Minimal 2 karakter';
          }
          return null;
        },
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: readOnly ? Colors.grey.shade500 : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon,
              size: 20,
              color: readOnly ? Colors.grey.shade400 : _primaryLight),
          prefixText: prefix,
          prefixStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  // ── Save Button ──
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Dialog Sukses ──
  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildAlertDialog(
        icon: Icons.check_rounded,
        iconColor: _accent,
        title: 'Tersimpan!',
        titleColor: _primary,
        message: 'Profil kamu berhasil diperbarui.',
        buttonColor: _primary,
      ),
    );
  }

  // ── Dialog Error ──
  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildAlertDialog(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        title: 'Gagal',
        titleColor: Colors.redAccent,
        message: message,
        buttonColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildAlertDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String message,
    required Color buttonColor,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}