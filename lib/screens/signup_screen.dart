import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _branchController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? newUser = userCredential.user;
      if (newUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': _nameController.text.trim(),
          'email': newUser.email,
          'branch': _branchController.text.trim(),
          'designation': _designationController.text.trim(),
          'role': 'faculty',
        });
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? "An error occurred."),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _branchController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/new_small_logo.png', height: 80),
                  const SizedBox(height: 20),
                  const Text("Create your Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4D4D4D))),
                  const SizedBox(height: 24),
                  _buildTextField(_nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, "Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_branchController, "Branch", Icons.business_center_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_designationController, "Designation", Icons.work_outline),
                  const SizedBox(height: 16),
                  _buildPasswordField(controller: _passwordController, label: "Password", isObscured: _obscurePassword, toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)),
                  const SizedBox(height: 16),
                  _buildPasswordField(controller: _confirmPasswordController, label: "Confirm Password", isObscured: _obscureConfirmPassword, toggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUpUser,
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                        : const Text("Sign Up"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your $hint' : null,
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String label, required bool isObscured, required VoidCallback toggleVisibility, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: toggleVisibility,
        ),
      ),
      validator: validator ?? (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
    );
  }
}
