import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:shiksha_sanchalan/screens/assign_duty_screen.dart';
import 'package:shiksha_sanchalan/screens/profile_screen.dart';
import 'package:shiksha_sanchalan/screens/seating_arrangement_screen.dart';
import 'package:shiksha_sanchalan/screens/settings_screen.dart';
import 'package:shiksha_sanchalan/screens/timetable_semester_screen.dart';

class AdminDashboard extends StatelessWidget {
  final UserModel userModel;
  const AdminDashboard({super.key, required this.userModel});

  // Function to show the role change dialog
  void _showChangeRoleDialog(BuildContext context, UserModel userToChange) {
    if (userToChange.uid == userModel.uid) {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome, ${userModel.name}!"),
          actions: [
            IconButton(
              tooltip: "My Profile",
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ProfileScreen(userModel: userModel),
                ));
              },
            ),
            IconButton(
              tooltip: "Settings",
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ));
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
              Tab(icon: Icon(Icons.people), text: "All Users"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AssignDutyScreen()),
            );
          },
          label: const Text("Assign Duty"),
          icon: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(context),
            _buildUsersListTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              _buildToolCard(context, title: "Seating Arrangement", icon: Icons.event_seat, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SeatingArrangementScreen()))),
              const SizedBox(height: 8),
              _buildToolCard(context, title: "Time Table Management", icon: Icons.schedule, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TimetableSemesterScreen()))),
            ],
          ),
        ),
        const Divider(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("Faculty Availability Status", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('facultyStatus').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No faculty statuses found."));
              final facultyDocs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: facultyDocs.length,
                itemBuilder: (context, index) {
                  final data = facultyDocs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: Icon(_getStatusIcon(data['status'] ?? ''), color: _getStatusColor(data['status'] ?? '')),
                      title: Text(data['facultyName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(data['status'] ?? 'Unknown', style: TextStyle(color: _getStatusColor(data['status'] ?? ''), fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersListTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No users found."));
        final userDocs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: userDocs.length,
          itemBuilder: (context, index) {
            final user = UserModel.fromMap(userDocs[index].id, userDocs[index].data() as Map<String, dynamic>);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null, child: user.photoUrl.isEmpty ? Text(user.name.isNotEmpty ? user.name.substring(0, 1) : 'U') : null),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(user.email),
                trailing: Text(user.role, style: TextStyle(color: user.role == 'admin' ? Colors.blue : Colors.green, fontWeight: FontWeight.bold)),
                onTap: () {
                  if (user.uid != userModel.uid) {
                    _showChangeRoleDialog(context, user);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(elevation: 2, child: ListTile(leading: Icon(icon, color: Colors.indigo), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios), onTap: onTap));
  }

  Color _getStatusColor(String status) {
    switch (status) { case 'Available': return Colors.green; case 'Engaged': return Colors.orange; case 'Unavailable': return Colors.red; default: return Colors.grey; }
  }

  IconData _getStatusIcon(String status) {
    switch (status) { case 'Available': return Icons.check_circle; case 'Engaged': return Icons.work; case 'Unavailable': return Icons.cancel; default: return Icons.help; }
  }
}
