import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:shiksha_sanchalan/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel userModel;
  const ProfileScreen({super.key, required this.userModel});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _currentUserModel;
  bool _isUploading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentUserModel = widget.userModel;
  }

  // Shows a bottom sheet with options to change or remove the picture
  void _showPictureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Change Picture'),
                onTap: () {
                  Navigator.of(context).pop();
                  _uploadProfilePicture();
                },
              ),
              if (_currentUserModel.photoUrl.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('Remove Picture', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile == null) return;

    setState(() { _isUploading = true; });

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/${_currentUserModel.uid}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(_currentUserModel.uid).update({'photoUrl': url});

      setState(() {
        _currentUserModel = UserModel(
          uid: _currentUserModel.uid,
          email: _currentUserModel.email,
          role: _currentUserModel.role,
          name: _currentUserModel.name,
          branch: _currentUserModel.branch,
          designation: _currentUserModel.designation,
          photoUrl: url,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to upload: $e")));
    } finally {
      if(mounted) setState(() { _isUploading = false; });
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_currentUserModel.photoUrl.isEmpty) return;

    setState(() { _isUploading = true; });

    try {
      await FirebaseStorage.instance.ref().child('profile_pictures/${_currentUserModel.uid}').delete();
      await FirebaseFirestore.instance.collection('users').doc(_currentUserModel.uid).update({'photoUrl': ''});

      setState(() {
        _currentUserModel = UserModel(
          uid: _currentUserModel.uid,
          email: _currentUserModel.email,
          role: _currentUserModel.role,
          name: _currentUserModel.name,
          branch: _currentUserModel.branch,
          designation: _currentUserModel.designation,
          photoUrl: '',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove picture: $e")));
    } finally {
      if(mounted) setState(() { _isUploading = false; });
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final password = await _showPasswordConfirmationDialog();
    if (password == null || password.isEmpty) return;

    setState(() { _isDeleting = true; });

    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      await user.getIdToken(true);

      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('deleteUserAccount');
      await callable.call();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deleted successfully.")));
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message ?? 'Could not verify password.'}"), backgroundColor: Colors.red));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message ?? 'Could not delete account.'}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  Future<String?> _showPasswordConfirmationDialog() {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("For your security, please enter your password to confirm account deletion."),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(passwordController.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updatedUser = await Navigator.of(context).push<UserModel>(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userModel: _currentUserModel),
                ),
              );
              if (updatedUser != null) {
                setState(() {
                  _currentUserModel = updatedUser;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildDetailCard(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: _isDeleting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            label: Text("Delete Account", style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onPressed: _isDeleting ? null : _deleteAccount,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _currentUserModel.photoUrl.isNotEmpty ? NetworkImage(_currentUserModel.photoUrl) : null,
              child: _currentUserModel.photoUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _isUploading ? null : _showPictureOptions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentUserModel.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          _currentUserModel.email,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(Icons.business_center_outlined, "Branch", _currentUserModel.branch),
            const Divider(),
            _buildDetailRow(Icons.work_outline, "Designation", _currentUserModel.designation),
            const Divider(),
            _buildDetailRow(Icons.verified_user_outlined, "Role", _currentUserModel.role),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}
