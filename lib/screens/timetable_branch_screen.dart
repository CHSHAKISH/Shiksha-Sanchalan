import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiksha_sanchalan/data/timetable_data.dart';
import 'package:shiksha_sanchalan/screens/timetable_entry_screen.dart';

class TimetableBranchScreen extends StatefulWidget {
  final int semesterNumber;

  const TimetableBranchScreen({super.key, required this.semesterNumber});

  @override
  State<TimetableBranchScreen> createState() => _TimetableBranchScreenState();
}

class _TimetableBranchScreenState extends State<TimetableBranchScreen> {
  // State for the common date and time
  DateTime? _commonDate;
  TimeOfDay? _commonTime;

  // Pickers for the common date and time
  Future<void> _pickCommonDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() => _commonDate = pickedDate);
    }
  }

  Future<void> _pickCommonTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => _commonTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = TimetableData.semesters[widget.semesterNumber] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Semester ${widget.semesterNumber} - Branches"),
      ),
      body: Column(
        children: [
          // Common Date/Time Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set Common Date/Time (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimePicker(
                            label: 'Common Date',
                            value: _commonDate != null ? DateFormat.yMMMd().format(_commonDate!) : 'Select Date',
                            onTap: _pickCommonDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimePicker(
                            label: 'Common Time',
                            value: _commonTime?.format(context) ?? 'Select Time',
                            onTap: _pickCommonTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        "This will pre-fill the next screen for all subjects.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Branch List
          Expanded(
            child: branches.isEmpty
                ? const Center(child: Text("No branches found for this semester."))
                : ListView.builder(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                final branchName = branch['name'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEDF0FF),
                      child: Icon(Icons.business_center_outlined, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(branchName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to the entry screen, passing the common values.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TimetableEntryScreen(
                            semesterNumber: widget.semesterNumber,
                            branchData: branch,
                            commonDate: _commonDate, // Pass common date
                            commonTime: _commonTime, // Pass common time
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for date/time picker fields
  Widget _buildDateTimePicker({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(value),
      ),
    );
  }
}
