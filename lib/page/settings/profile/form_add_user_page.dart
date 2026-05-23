import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/unit.dart';
import '../../../models/user.dart';
import '../../../services/unit_service.dart';
import '../../../services/user_service.dart';

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;
  final String? errorText;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() =>
      isExpanded ? _closeDropdown() : _openDropdown();

  void _openDropdown() {
    setState(() => isExpanded = true);
    _controller.forward();

    final renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.scale(
                scaleY: _controller.value,
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: widget.items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada unit terdaftar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) => InkWell(
                            onTap: () {
                              widget.onChanged(widget.items[index]);
                              _closeDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.value == widget.items[index]
                                    ? const Color(0xFFF0F9FF)
                                    : null,
                              ),
                              child: Text(
                                widget.items[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.value == widget.items[index]
                                      ? const Color(0xFF2E5D6F)
                                      : Colors.black87,
                                  fontWeight:
                                      widget.value == widget.items[index]
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() => isExpanded = false);
    _controller.reverse().then((_) => _overlayEntry?.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _dropdownKey,
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? 'Pilih unit kerja',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final validations = _getPasswordValidations(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Persyaratan Password:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...validations.entries
            .map((entry) => _buildValidationItem(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isValid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, bool> _getPasswordValidations(String password) {
    return {
      'Minimal 6 karakter': password.length >= 6,
      'Mengandung huruf besar': password.contains(RegExp(r'[A-Z]')),
      'Mengandung angka': password.contains(RegExp(r'[0-9]')),
      'Mengandung simbol (!@#\$%^&*)':
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }
}

class FormAddUserPage extends StatefulWidget {
  const FormAddUserPage({super.key});

  @override
  State<FormAddUserPage> createState() => _FormAddUserPageState();
}

class _FormAddUserPageState extends State<FormAddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final UnitService _unitService = UnitService();
  final UserService _userService = UserService();

  List<UnitModel> _unitList = [];
  UnitModel? _selectedUnitModel;
  int selectedLevel = 2;

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final telegramUsernameController = TextEditingController();
  final telegramChatIdController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingUnits = true;
  bool _isCheckingChatId = false;
  String? _chatIdStatus;

  String? _unitError;
  String? _nameError;
  String? _usernameError;
  String? _telegramUsernameError;
  String? _telegramChatIdError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _unitService.fetchAll();
      setState(() {
        _unitList = units;
        _isLoadingUnits = false;
      });
    } catch (e) {
      setState(() => _isLoadingUnits = false);
    }
  }

  Future<void> _checkChatId() async {
    final username =
        telegramUsernameController.text.trim().replaceAll('@', '');

    if (username.isEmpty) {
      setState(() =>
          _telegramUsernameError = 'Isi username Telegram dulu');
      return;
    }

    setState(() {
      _isCheckingChatId = true;
      _chatIdStatus = null;
      telegramChatIdController.clear();
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('telegram_users')
          .doc(username)
          .get();

      if (doc.exists) {
        // ✅ FIX: convert ke string dulu apapun tipenya (int atau string) dari Firestore
        final chatId = doc.data()?['chat_id']?.toString() ?? '';
        setState(() {
          telegramChatIdController.text = chatId;
          _chatIdStatus = 'success';
          _telegramChatIdError = null;
        });
      } else {
        setState(() => _chatIdStatus = 'not_found');
      }
    } catch (e) {
      setState(() => _chatIdStatus = 'error');
    } finally {
      setState(() => _isCheckingChatId = false);
    }
  }

  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _clearAllErrors() {
    setState(() {
      _unitError = null;
      _nameError = null;
      _usernameError = null;
      _telegramUsernameError = null;
      _telegramChatIdError = null;
      _passwordError = null;
    });
  }

  bool _validateAllFields() {
    _clearAllErrors();
    bool isValid = true;

    if (_selectedUnitModel == null) {
      setState(() => _unitError = 'Pilih unit kerja terlebih dahulu');
      isValid = false;
    }

    if (fullNameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Nama tidak boleh kosong');
      isValid = false;
    } else if (fullNameController.text.trim().length < 2) {
      setState(() => _nameError = 'Nama minimal 2 karakter');
      isValid = false;
    }

    if (usernameController.text.trim().isEmpty) {
      setState(() => _usernameError = 'Username tidak boleh kosong');
      isValid = false;
    } else {
      String username = usernameController.text.trim();
      if (username.startsWith('@')) username = username.substring(1);
      if (username.length < 3) {
        setState(() => _usernameError = 'Username minimal 3 karakter');
        isValid = false;
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        setState(() => _usernameError =
            'Username hanya boleh huruf, angka, dan underscore');
        isValid = false;
      }
    }

    if (telegramUsernameController.text.trim().isEmpty) {
      setState(() =>
          _telegramUsernameError = 'Username Telegram tidak boleh kosong');
      isValid = false;
    } else {
      String username = telegramUsernameController.text.trim();
      if (username.startsWith('@')) username = username.substring(1);
      if (!RegExp(r'^[a-zA-Z0-9_]{5,32}$').hasMatch(username)) {
        setState(() => _telegramUsernameError =
            'Username Telegram harus 5-32 karakter (huruf, angka, underscore)');
        isValid = false;
      }
    }

    if (telegramChatIdController.text.trim().isEmpty) {
      setState(() =>
          _telegramChatIdError = 'Chat ID Telegram tidak boleh kosong');
      isValid = false;
    } else {
      if (!RegExp(r'^-?\d+$')
          .hasMatch(telegramChatIdController.text.trim())) {
        setState(() => _telegramChatIdError = 'Chat ID harus berupa angka');
        isValid = false;
      }
    }

    if (passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password tidak boleh kosong');
      isValid = false;
    } else {
      String password = passwordController.text;
      List<String> errors = [];
      if (password.length < 6) errors.add("minimal 6 karakter");
      if (!password.contains(RegExp(r'[A-Z]'))) errors.add("huruf besar");
      if (!password.contains(RegExp(r'[0-9]'))) errors.add("angka");
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
        errors.add("simbol (!@#\$%^&*)");
      if (errors.isNotEmpty) {
        setState(() => _passwordError =
            'Password harus mengandung: ${errors.join(', ')}');
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _saveUser() async {
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final usernameExist = await _userService
          .isUsernameExist(usernameController.text.trim());
      if (usernameExist) {
        setState(() {
          _isLoading = false;
          _usernameError = 'Username sudah terdaftar dalam sistem';
        });
        return;
      }

      final chatIdExist = await _userService
          .isChatIdExist(telegramChatIdController.text.trim());
      if (chatIdExist) {
        setState(() {
          _isLoading = false;
          _telegramChatIdError =
              'Chat ID Telegram sudah terdaftar dalam sistem';
        });
        return;
      }

      String telegramUsername = telegramUsernameController.text.trim();
      if (telegramUsername.startsWith('@')) {
        telegramUsername = telegramUsername.substring(1);
      }

      final username = usernameController.text.trim().startsWith('@')
          ? usernameController.text.trim()
          : '@${usernameController.text.trim()}';

      final newUser = UserModel(
        name: fullNameController.text.trim(),
        username: username,
        unit: _selectedUnitModel!.namaUnit.toLowerCase(), // ✅ simpan lowercase
        kodeUnit: _selectedUnitModel!.kodeUnit,
        level: selectedLevel,
        password: passwordController.text.trim(),
        added: getCurrentDate(),
        usernameTelegram: telegramUsername,
        chatIdTelegram: telegramChatIdController.text.trim(), // tetap string di model, dikonversi saat toMap()
        status: 1,
      );

      await _userService.addUser(newUser);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessAlert();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5D6F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'User berhasil ditambahkan ke sistem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text('OK',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedUnitModel = null;
      selectedLevel = 2;
      fullNameController.clear();
      usernameController.clear();
      telegramUsernameController.clear();
      telegramChatIdController.clear();
      passwordController.clear();
      _isPasswordVisible = false;
      _chatIdStatus = null;
    });
    _clearAllErrors();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    Widget? bottomWidget,
    String? errorText,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                readOnly ? Colors.grey.shade100 : const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: readOnly
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFF2E5D6F), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffixIcon,
          ),
          style: TextStyle(
            color: readOnly ? Colors.grey.shade600 : Colors.black87,
            fontWeight: readOnly ? FontWeight.w600 : FontWeight.normal,
            letterSpacing: readOnly ? 1.5 : 0,
          ),
          onChanged: readOnly
              ? null
              : (value) {
                  if (label == "Nama Lengkap" && _nameError != null) {
                    setState(() => _nameError = null);
                  } else if (label == "Username" && _usernameError != null) {
                    setState(() => _usernameError = null);
                  } else if (label == "Username Telegram" &&
                      _telegramUsernameError != null) {
                    setState(() {
                      _telegramUsernameError = null;
                      _chatIdStatus = null;
                      telegramChatIdController.clear();
                    });
                  } else if (label == "Password") {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                    setState(() {});
                  }
                },
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (bottomWidget != null) bottomWidget,
      ],
    );
  }

  Widget _buildChatIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat ID Telegram',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: telegramChatIdController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _chatIdStatus == 'success'
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'Klik "Cek Chat ID"',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5D6F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: _isCheckingChatId ? null : _checkChatId,
                child: _isCheckingChatId
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cek\nChat ID',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
              ),
            ),
          ],
        ),
        if (_chatIdStatus == 'success') ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Chat ID ditemukan!',
                style: TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ),
        ],
        if (_chatIdStatus == 'not_found') ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'User belum chat bot Telegram. Minta user chat dulu ke @jagagrid_pln_bot',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
        if (_chatIdStatus == 'error') ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.error, color: Colors.orange, size: 16),
              SizedBox(width: 6),
              Text(
                'Gagal mengambil data, coba lagi',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ],
          ),
        ],
        if (_telegramChatIdError != null) ...[
          const SizedBox(height: 8),
          Text(
            _telegramChatIdError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKodeUnitField() {
    final kode = _selectedUnitModel?.kodeUnit ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kode Unit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kode.isNotEmpty
                ? const Color(0xFFE8F4F8)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kode.isNotEmpty
                  ? const Color(0xFF2E5D6F).withOpacity(0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tag,
                color: kode.isNotEmpty
                    ? const Color(0xFF2E5D6F)
                    : Colors.grey.shade400,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                kode.isNotEmpty ? kode : 'Otomatis terisi setelah pilih unit',
                style: TextStyle(
                  fontSize: kode.isNotEmpty ? 16 : 14,
                  fontWeight:
                      kode.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  color: kode.isNotEmpty
                      ? const Color(0xFF2E5D6F)
                      : Colors.grey.shade400,
                  letterSpacing: kode.isNotEmpty ? 2 : 0,
                ),
              ),
              if (kode.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⚡ Auto',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5D6F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Tambah User Baru",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _isLoadingUnits
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E5D6F),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Memuat daftar unit...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : CustomDropdown(
                      value: _selectedUnitModel?.namaUnit,
                      items: _unitList.map((u) => u.namaUnit).toList(),
                      labelText: "Pilih Unit Kerja",
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitModel = _unitList
                              .firstWhere((u) => u.namaUnit == value);
                          _unitError = null;
                        });
                      },
                      errorText: _unitError,
                    ),

              const SizedBox(height: 16),
              _buildKodeUnitField(),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Level Unit",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 1,
                              groupValue: selectedLevel,
                              onChanged: (value) =>
                                  setState(() => selectedLevel = value!),
                              activeColor: const Color(0xFF2E5D6F),
                            ),
                            const Text('Unit Induk',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 2,
                              groupValue: selectedLevel,
                              onChanged: (value) =>
                                  setState(() => selectedLevel = value!),
                              activeColor: const Color(0xFF2E5D6F),
                            ),
                            const Text('Unit Layanan',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildField("Nama Lengkap", fullNameController,
                  errorText: _nameError),
              const SizedBox(height: 20),
              _buildField("Username", usernameController,
                  errorText: _usernameError),
              const SizedBox(height: 20),
              _buildField("Username Telegram", telegramUsernameController,
                  errorText: _telegramUsernameError),
              const SizedBox(height: 20),

              _buildChatIdField(),
              const SizedBox(height: 20),

              _buildField(
                "Password",
                passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible),
                ),
                bottomWidget: passwordController.text.isNotEmpty
                    ? PasswordStrengthIndicator(
                        password: passwordController.text)
                    : null,
                errorText: _passwordError,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Simpan User",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    telegramUsernameController.dispose();
    telegramChatIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}