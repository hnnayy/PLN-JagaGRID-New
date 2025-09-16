import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigation_menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Modern color scheme
  static const Color primaryColor = Color(0xFF125E72); // Indigo
  static const Color primaryDark = Color(0xFF14A2B9); // Darker indigo
  static const Color backgroundColor = Color(0xFFF8FAFC); // Light gray
  static const Color cardColor = Colors.white;
  static const Color accentColor = Color(0xFF10B981); // Emerald
  static const Color textPrimary = Color(0xFF1E293B); // Dark gray
  static const Color textSecondary = Color(0xFF64748B); // Medium gray
  static const Color inputFill = Color(0xFFF1F5F9); // Light blue gray

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.1),
              accentColor.withOpacity(0.05),
              backgroundColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 0),
                  // Logo/Icon Section
                  Container(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                  const SizedBox(height:0),
                  
                  // Welcome Text
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk ke akun Anda untuk melanjutkan',
                    style: TextStyle(
                      fontSize: 16, 
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Login Form Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 40,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username Field
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: usernameController,
                          decoration: _inputDecoration(
                            hintText: 'Masukkan username Anda',
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: _inputDecoration(
                            hintText: 'Masukkan password Anda',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        
                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ).copyWith(
                              backgroundColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return primaryDark;
                                }
                                if (states.contains(MaterialState.disabled)) {
                                  return textSecondary.withOpacity(0.3);
                                }
                                return primaryColor;
                              }),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    Widget? suffixIcon,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintText: hintText,
      hintStyle: TextStyle(
        color: textSecondary,
        fontSize: 15,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textSecondary, size: 20)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String username = usernameController.text.trim();
      if (!username.startsWith('@')) {
        username = '@$username';
      }
      final password = passwordController.text.trim();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isNotEmpty) {
        // Login success, navigate to home (NavigationMenu)
        // Simpan session ke SharedPreferences
        final userData = query.docs.first.data();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_username', userData['username'] ?? '');
        await prefs.setString('session_name', userData['name'] ?? '');
        await prefs.setString('session_unit', userData['unit'] ?? '');
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationMenu()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Username atau password tidak valid. Silakan coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan. Pastikan koneksi internet Anda stabil.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}