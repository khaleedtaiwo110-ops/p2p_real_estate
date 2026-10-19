import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../services/storage_service.dart';
import '../explore/explore_screen.dart'; // Adjust import path according to your project structure

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true; // Toggle for password visibility
  
  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  String _selectedRole = 'tenant';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Base URL Resolver
  String get _baseUrl {
    if (kIsWeb) return 'https://p2p-real-estate-backend.onrender.com/api';
    if (Platform.isAndroid) return 'https://p2p-real-estate-backend.onrender.com/api'; // Android Emulator alias
    return 'https://p2p-real-estate-backend.onrender.com/api';
  }

  // Google Sign In Instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '38245920321-80666d439185ufvatm7324t92jaf0ods.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Wipe all previous user session data BEFORE initiating the request
    await StorageService.clearToken();

    final String endpoint = _isLogin
        ? '$_baseUrl/auth/login/'
        : '$_baseUrl/auth/register/';

    final Map<String, dynamic> payload = _isLogin
        ? {
            'username': _usernameController.text.trim(),
            'password': _passwordController.text.trim(),
          }
        : {
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'role': _selectedRole,
          };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      // Verify response content type prior to parsing JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        _showErrorDialog(
          'Server returned HTML (${response.statusCode}) instead of JSON.\n\n'
          'Check that the route exists in your backend urls.py and ends with a trailing slash.'
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String token = data['token'] ?? data['access'] ?? '';

        if (token.isNotEmpty) {
          // Save the fresh token for the newly logged-in account
          await StorageService.saveToken(token);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Welcome back!' : 'Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Destroy navigation history so old screen widgets/states are unmounted
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ExploreScreen()),
          (route) => false,
        );
      } else {
        final errorMsg = data['detail'] ?? data['message'] ?? 'Authentication failed.';
        _showErrorDialog(errorMsg.toString());
      }
    } on TimeoutException {
      _showErrorDialog('Connection timed out. Please check if your Django backend is running at $_baseUrl');
    } catch (e) {
      _showErrorDialog('Could not connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Clear previous authentication data first
      await StorageService.clearToken();

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      // Exchange Google Tokens with your Django Backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_token': accessToken,
          'id_token': idToken,
        }),
      ).timeout(const Duration(seconds: 10));

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        _showErrorDialog(
          'Server returned HTML (${response.statusCode}) instead of JSON.\n\n'
          'Check that the Google auth route exists in your backend urls.py and ends with a trailing slash.'
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String token = data['token'] ?? data['access'] ?? '';
        if (token.isNotEmpty) {
          await StorageService.saveToken(token);
        }

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ExploreScreen()),
          (route) => false,
        );
      } else {
        _showErrorDialog('Google Sign-In failed on backend.');
      }
    } on TimeoutException {
      _showErrorDialog('Google auth timed out connecting to backend server.');
    } catch (e) {
      _showErrorDialog('Google Sign-In Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=1600',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(Icons.home_work_rounded, size: 56, color: Colors.blueAccent),
                            const SizedBox(height: 12),
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 24),

                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Full Name', Icons.person_outline),
                                validator: (val) => val == null || val.trim().isEmpty ? 'This field is required' : null,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('I am a...', Icons.badge_outlined),
                                items: const [
                                  DropdownMenuItem(value: 'tenant', child: Text('Tenant / Buyer')),
                                  DropdownMenuItem(value: 'landlord', child: Text('Landlord / Property Owner')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Username Field (Present on both Login & Register)
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Username', Icons.person_outline),
                              validator: (val) => val == null || val.trim().isEmpty ? 'This field is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Email Field (Shown during Registration)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Email', Icons.email_outlined),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'This field is required';
                                  }
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(val.trim())) {
                                    return 'invalid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                'Password', 
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'This field is required';
                                }
                                if (val.length < 4) {
                                  return 'Password too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      )
                                    : Text(_isLogin ? 'Log In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: const [
                                Expanded(child: Divider(color: Colors.grey)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google Sign In Button
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                                label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 15)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isLogin ? "Don't have an account?" : "Already have an account?", style: const TextStyle(color: Colors.grey)),
                                TextButton(
                                  onPressed: () => setState(() => _isLogin = !_isLogin),
                                  child: Text(_isLogin ? 'Sign Up' : 'Log In'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E293B).withOpacity(0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}