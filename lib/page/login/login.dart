import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 85,
                    height: 85,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E5D6F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5D6F),
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Masuk ke akun Anda',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        const Text('Username', style: TextStyle(fontSize: 12, color: Color(0xFF2E5D6F), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: usernameController,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 20),
                        // Password
                        const Text('Password', style: TextStyle(fontSize: 12, color: Color(0xFF2E5D6F), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: _inputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E5D6F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3FFFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
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
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationMenu()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login gagal. Cek data Anda.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
