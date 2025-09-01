import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:shiksha_sanchalan/screens/profile_screen.dart';
import 'package:shiksha_sanchalan/screens/seating_arrangement_screen.dart';
import 'package:shiksha_sanchalan/screens/settings_screen.dart';
import 'package:shiksha_sanchalan/screens/timetable_semester_screen.dart';
import 'package:shiksha_sanchalan/services/notification_service.dart';

class FacultyDashboard extends StatefulWidget {
  final UserModel userModel;
  const FacultyDashboard({super.key, required this.userModel});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final NotificationService _notificationService = NotificationService();
  String _currentStatus = 'Unavailable';

  @override
  void initState() {
    super.initState();
    _notificationService.initNotifications();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() { _currentStatus = newStatus; });
    try {
      await FirebaseFirestore.instance.collection('facultyStatus').doc(widget.userModel.uid).set({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'facultyName': widget.userModel.name,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome, ${widget.userModel.name}!"),
          actions: [
            IconButton(
              tooltip: "My Profile",
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen(userModel: widget.userModel)));
              },
            ),
            IconButton(
              tooltip: "Settings",
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
        body: TabBarView(
          children: [
            _buildDashboardTab(context),
            _buildUsersListTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set Your Current Availability:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('facultyStatus').doc(widget.userModel.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      _currentStatus = data['status'] ?? 'Unavailable';
                    }
                    return Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        ChoiceChip(label: const Text('Available'), selected: _currentStatus == 'Available', onSelected: (isSelected) => isSelected ? _updateStatus('Available') : null, selectedColor: Colors.green[100]),
                        ChoiceChip(label: const Text('Unavailable'), selected: _currentStatus == 'Unavailable', onSelected: (isSelected) => isSelected ? _updateStatus('Unavailable') : null, selectedColor: Colors.red[100]),
                        ChoiceChip(label: const Text('Engaged'), selected: _currentStatus == 'Engaged', onSelected: (isSelected) => isSelected ? _updateStatus('Engaged') : null, selectedColor: Colors.orange[100]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildToolCard(context, title: "Seating Arrangement", icon: Icons.event_seat, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SeatingArrangementScreen()))),
                const SizedBox(height: 8),
                _buildToolCard(context, title: "Time Table Management", icon: Icons.schedule, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TimetableSemesterScreen()))),
                const Divider(height: 32, thickness: 1),
                const Text("My Assigned Duties", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('duties').where('facultyId', isEqualTo: widget.userModel.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("You have no duties assigned.")));
              final duties = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: duties.length,
                itemBuilder: (context, index) {
                  final duty = duties[index].data() as Map<String, dynamic>;
                  final dutyDateTime = (duty['dutyDateTime'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_ind, color: Colors.indigo),
                      title: Text("Room: ${duty['roomNo']}"),
                      subtitle: Text(DateFormat('EEE, MMM d, yyyy  -  h:mm a').format(dutyDateTime)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersListTab() {
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
}
