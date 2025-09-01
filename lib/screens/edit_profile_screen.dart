import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userModel;
  const EditProfileScreen({super.key, required this.userModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _branchController;
  late TextEditingController _designationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userModel.name);
    _branchController = TextEditingController(text: widget.userModel.branch);
    _designationController = TextEditingController(text: widget.userModel.designation);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'branch': _branchController.text.trim(),
        'designation': _designationController.text.trim(),
      };

      // Update the data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update(updatedData);

      // Create an updated user model to pass back
      final updatedUserModel = UserModel(
        uid: widget.userModel.uid,
        email: widget.userModel.email,
        role: widget.userModel.role,
        photoUrl: widget.userModel.photoUrl,
        name: updatedData['name']!,
        branch: updatedData['branch']!,
        designation: updatedData['designation']!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
        // Pop the screen and return the updated model
        Navigator.of(context).pop(updatedUserModel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_branchController, "Branch", Icons.business_center_outlined),
              const SizedBox(height: 16),
              _buildTextField(_designationController, "Designation", Icons.work_outline),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }
}
