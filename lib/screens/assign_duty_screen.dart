import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AssignDutyScreen extends StatefulWidget {
  const AssignDutyScreen({super.key});

  @override
  State<AssignDutyScreen> createState() => _AssignDutyScreenState();
}

class _AssignDutyScreenState extends State<AssignDutyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  // State variables for the form
  String? _selectedFacultyId; // Store the ID (String) instead of the whole document
  List<DocumentSnapshot> _availableFaculty = []; // To hold the list of available faculty

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // Function to show the date picker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Function to show the time picker
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Function to assign the duty
  Future<void> _assignDuty() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFacultyId == null || _selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Find the full document from the stored list using the ID
        final selectedFacultyDoc = _availableFaculty.firstWhere(
              (doc) => doc.id == _selectedFacultyId,
        );

        // Combine date and time
        final dutyTimestamp = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final facultyData = selectedFacultyDoc.data() as Map<String, dynamic>;
        final facultyName = facultyData['facultyName'] ?? 'Unknown Faculty';

        // Add to 'duties' collection
        await FirebaseFirestore.instance.collection('duties').add({
          'facultyId': selectedFacultyDoc.id,
          'facultyName': facultyName,
          'roomNo': _roomController.text.trim(),
          'dutyDateTime': Timestamp.fromDate(dutyTimestamp),
          'assignedAt': FieldValue.serverTimestamp(),
          'assignedBy': FirebaseAuth.instance.currentUser?.uid,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Duty assigned successfully!"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to assign duty: $e")),
        );
      } finally {
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Invigilation Duty"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown to select faculty
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('facultyStatus').where('status', isEqualTo: 'Available').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Store the list of documents to use later
                  _availableFaculty = snapshot.data!.docs;

                  // If the list is empty, show a disabled field
                  if (_availableFaculty.isEmpty) {
                    return const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'No faculty available',
                        border: OutlineInputBorder(),
                        enabled: false,
                      ),
                      child: Text(''),
                    );
                  }

                  return DropdownButtonFormField<String>( // Use String as the type
                    decoration: const InputDecoration(
                      labelText: "Select Available Faculty",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedFacultyId,
                    items: _availableFaculty.map((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      final facultyName = data?['facultyName'] as String? ?? 'No Name';
                      return DropdownMenuItem<String>(
                        value: doc.id, // The value is now the document ID (a String)
                        child: Text(facultyName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFacultyId = value; // Store the selected ID
                      });
                    },
                    validator: (value) => value == null ? 'Please select a faculty' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Room Number Field
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: "Room Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date and Time Pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate == null ? 'Select Date' : DateFormat.yMMMd().format(_selectedDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Assign Button
              ElevatedButton(
                onPressed: _isLoading ? null : _assignDuty,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Assign Duty", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
