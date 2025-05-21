import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  // ignore: prefer_final_fields
  bool _isTestingConnection = false;

  void _log(String message, {String type = 'INFO'}) {
    final ts = DateTime.now().toIso8601String();
    debugPrint('[$ts] [$type] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('Initializing Login Screen');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _checkNetworkConnectivity()) {
      _showSnackBar('لا يوجد اتصال بالإنترنت', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _log('Submitting login');

    try {
      await _performLogin();
    } catch (e) {
      _log('Unexpected error: $e', type: 'ERROR');
      _showSnackBar('حدث خطأ غير متوقع', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _log('Finished login attempt');
    }
  }

  Future<void> _performLogin() async {
    final client = http.Client();
    try {
      final uri = Uri.parse('https://dev-moamen.pro/test/login.php');
      final body = jsonEncode({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      });
      _log('POST $uri → $body');

      final stopwatch = Stopwatch()..start();
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      _log(
        'Response ${response.statusCode} '
        'in ${stopwatch.elapsedMilliseconds}ms: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _log('Login success: $data');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', _usernameController.text.trim());

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/voters');
        }
      } else {
        _log('Login failed: ${response.statusCode}', type: 'WARNING');
        _showSnackBar('فشل تسجيل الدخول: بيانات غير صحيحة', Colors.red);
      }
    } on TimeoutException {
      _showSnackBar('انتهت مهلة الاتصال بالخادم', Colors.orange);
    } on SocketException {
      _showSnackBar('لا يمكن الاتصال بالخادم', Colors.red);
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع: $e', Colors.red);
    } finally {
      client.close();
    }
  }

  Future<bool> _checkNetworkConnectivity() async {
    _log('Checking connectivity...');
    if (kIsWeb) {
      // assume browser online status
      return true;
    }
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _log('Network check failed: $e', type: 'ERROR');
      return false;
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
      );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color.fromARGB(255, 11, 19, 30).withOpacity(0.9),
                  const Color.fromARGB(255, 34, 42, 51).withOpacity(0.7),
                ],
              ),
            ),
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: Container(color: Colors.transparent)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 8,
                  color: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.lock_person, size: 80, color: Colors.white)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(),
                        const SizedBox(height: 24),
                        Text(
                          'تسجيل الدخول',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(label: 'اسم المستخدم', icon: Icons.person_outline),
                          validator: (v) => v?.isEmpty ?? true ? 'يجب إدخال اسم المستخدم' : null,
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(label: 'كلمة المرور', icon: Icons.lock_outline),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'يجب إدخال كلمة المرور';
                            if (v!.length < 6) return 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromARGB(179, 253, 253, 253)),
      prefixIcon: Icon(icon, color: const Color.fromARGB(179, 255, 255, 255)),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: const Color.fromRGBO(255, 255, 255, 1)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
    );
  }

  OutlineInputBorder _inputBorder({Color color = const Color.fromARGB(136, 255, 255, 255)}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  Widget _buildLoginButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 253, 253).withOpacity(0.2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color.fromARGB(137, 255, 255, 255), width: 1),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );

    
}