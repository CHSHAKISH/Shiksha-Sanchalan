import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';

class AllUsersPage extends StatelessWidget {
  final UserModel currentUser;
  const AllUsersPage({super.key, required this.currentUser});

  // Function to show the role change dialog
  void _showChangeRoleDialog(BuildContext context, UserModel userToChange) {
    if (userToChange.uid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot change your own role.")),
      );
      return;
    }

    bool isCurrentlyAdmin = userToChange.role == 'admin';
    String dialogTitle = isCurrentlyAdmin ? "Demote ${userToChange.name}" : "Promote ${userToChange.name}";
    String dialogContent = isCurrentlyAdmin
        ? "Do you want to remove this user from the Admin role? They will become a Faculty."
        : "Do you want to promote this user to an Admin?";
    String buttonText = isCurrentlyAdmin ? "Remove From Admin" : "Make Admin";
    String newRole = isCurrentlyAdmin ? "faculty" : "admin";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyAdmin ? Colors.red : Colors.green,
              ),
              child: Text(buttonText),
              onPressed: () {
                _changeUserRole(context, userToChange.uid, newRole);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to update the user's role in Firestore
  Future<void> _changeUserRole(BuildContext context, String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User role updated successfully."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update role: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userDocs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final user = UserModel.fromMap(userDocs[index].id, userDocs[index].data() as Map<String, dynamic>);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty ? Text(user.name.isNotEmpty ? user.name.substring(0, 1) : 'U') : null,
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(user.email),
                  trailing: Text(
                    user.role,
                    style: TextStyle(
                      color: user.role == 'admin' ? Theme.of(context).primaryColor : const Color(0xFF01B634),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Only admins can change roles
                    if (currentUser.role == 'admin') {
                      _showChangeRoleDialog(context, user);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
