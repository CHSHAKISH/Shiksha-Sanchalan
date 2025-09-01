import 'package:flutter/material.dart';
import 'package:shiksha_sanchalan/screens/timetable_branch_screen.dart';

class TimetableSemesterScreen extends StatelessWidget {
  const TimetableSemesterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Semester"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 8, // We have 8 semesters
        itemBuilder: (context, index) {
          final semesterNumber = index + 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                child: Text(
                  semesterNumber.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                "Semester $semesterNumber",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to the branch selection screen, passing the semester number.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TimetableBranchScreen(semesterNumber: semesterNumber),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
