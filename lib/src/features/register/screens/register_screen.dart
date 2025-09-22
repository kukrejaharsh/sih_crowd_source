import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/features/login/screens/login_screen.dart';
import 'package:sih_crowd_source/src/features/register/widgets/validated_field.dart';


// Renamed to SignUpScreen for consistency
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Use a GlobalKey for standard Form validation
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for the Civic Reporter app ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // --- State Variables ---
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// --- Image Picker (Unchanged) ---
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  /// --- Form Submission ---
  Future<void> _register() async {
    // Trigger form validation. If it fails, do nothing.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthStateProvider>(context, listen: false);

      // Call the signUp method with the correct parameters for your UserModel
      final error = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        profileImage: _profileImage,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registration successful! Please check your email to verify and then login.'),
            backgroundColor: Colors.green,
          ));
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        } else {
          _showError('Registration failed: $error');
        }
      }
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // This UI is now tailored to your Civic Reporter app, using the same style
          Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
              Color(0xFF6C63FF),
              Color.fromARGB(255, 4, 129, 167)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Create Account",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 30),

                    // Text Fields with built-in validation
                    CustomValidatedField(
                        controller: _nameController,
                        icon: Icons.person,
                        hint: "Full Name",
                        validator: (val) => (val == null || val.isEmpty) ? "Please enter your name" : null
                    ),
                    CustomValidatedField(
                        controller: _emailController,
                        icon: Icons.email,
                        hint: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => (val == null || !val.contains('@')) ? "Enter a valid email" : null
                    ),
                    CustomValidatedField(
                        controller: _phoneController,
                        icon: Icons.phone,
                        hint: "Phone Number ",
                        keyboardType: TextInputType.phone,
                        validator: (val) => (val == null || val.length ==10) ? "Phone number must be at 10 digits" : null
                        // No validator for optional field
                    ),
                    CustomValidatedField(
                        controller: _passwordController,
                        icon: Icons.lock,
                        hint: "Password",
                        obscureText: true,
                        validator: (val) => (val == null || val.length < 6) ? "Password must be at least 6 characters" : null
                    ),
                    CustomValidatedField(
                        controller: _confirmPasswordController,
                        icon: Icons.lock_outline,
                        hint: "Confirm Password",
                        obscureText: true,
                        validator: (val) => val != _passwordController.text ? "Passwords do not match" : null
                    ),
                    
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14)),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003366)))
                        : const Text("Register",
                          style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF003366),
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text("Already have an account? Login",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}