import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:shiksha_sanchalan/screens/faculty_assignment_page.dart';
import 'package:shiksha_sanchalan/screens/faculty_availability_page.dart';
import 'package:shiksha_sanchalan/screens/notification_screen.dart';
import 'package:shiksha_sanchalan/screens/seating_arrangement_screen.dart';
import 'package:shiksha_sanchalan/screens/timetable_semester_screen.dart';

class DashboardPage extends StatelessWidget {
  final UserModel userModel;
  const DashboardPage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    bool isAdmin = userModel.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Color(0xff1F319D),
        title: Image.asset(
          'assets/new_small_logo.png', // Using your small logo asset
          height: 50,
        ),

        // Text("Shiksha Sanchalan", style: TextStyle(color: Color(0xff1F319D), fontSize: 30, fontWeight: FontWeight.bold),),

        actions: [
          // StreamBuilder to listen for unread notifications
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: userModel.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: "Notifications",
                    icon: const Icon(Icons.notifications_none_outlined),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardCard(
            context: context,
            title: "Seating\nArrangement",
            icon: Icons.event_seat_outlined,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SeatingArrangementScreen()));
            },
          ),
          _buildDashboardCard(
            context: context,
            title: "Faculty\nAvailability",
            icon: Icons.person_search_outlined,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FacultyAvailabilityPage(currentUser: userModel),
              ));
            },
          ),
          // Only show the assignment card to admins
          if (isAdmin)
            _buildDashboardCard(
              context: context,
              title: "Faculty\nAssignment",
              icon: Icons.assignment_ind_outlined,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FacultyAssignmentPage(currentUser: userModel),
                ));
              },
            ),
          _buildDashboardCard(
            context: context,
            title: "Time Table\nManagement",
            icon: Icons.schedule_outlined,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TimetableSemesterScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Helper widget to build the beautiful dashboard cards from your design
  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFEDF0FF),
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4D4D4D),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
