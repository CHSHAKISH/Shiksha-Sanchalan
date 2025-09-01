import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FacultyAssignmentPage extends StatefulWidget {
  final UserModel currentUser;
  const FacultyAssignmentPage({super.key, required this.currentUser});

  @override
  State<FacultyAssignmentPage> createState() => _FacultyAssignmentPageState();
}

class _FacultyAssignmentPageState extends State<FacultyAssignmentPage> {
  String _searchQuery = '';
  String? _statusFilter;
  List<QueryDocumentSnapshot> _currentDocs = [];

  // This function shows the dialog to assign a duty
  void _showAssignDutyDialog(BuildContext context, Map<String, dynamic> facultyData) {
    final formKey = GlobalKey<FormState>();
    final roomController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Assign Duty to ${facultyData['facultyName']}"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: roomController,
                      decoration: const InputDecoration(hintText: "Enter Room Number"),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                              child: Text(selectedDate != null ? DateFormat.yMMMd().format(selectedDate!) : 'Select'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                              child: Text(selectedTime?.format(context) ?? 'Select'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate() && selectedDate != null && selectedTime != null) {
                      setDialogState(() => isLoading = true);
                      await _assignDuty(facultyData, roomController.text, selectedDate!, selectedTime!);
                      if (mounted) Navigator.of(ctx).pop();
                    }
                  },
                  child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Assign"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // This function now handles the database updates
  Future<void> _assignDuty(Map<String, dynamic> facultyData, String room, DateTime date, TimeOfDay time) async {
    try {
      final dutyTimestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final facultyId = facultyData['uid'];

      await FirebaseFirestore.instance.collection('duties').add({
        'facultyId': facultyId,
        'facultyName': facultyData['facultyName'],
        'roomNo': room,
        'dutyDateTime': Timestamp.fromDate(dutyTimestamp),
        'assignedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('facultyStatus').doc(facultyId).update({
        'status': 'Engaged',
        'assignedRoom': room,
        'assignedDateTime': Timestamp.fromDate(dutyTimestamp),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duty assigned successfully!"), backgroundColor: Colors.green));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to assign duty: $e"), backgroundColor: Colors.red));
    }
  }

  // Function to generate and print the PDF
  Future<void> _printAssignmentList() async {
    final pdf = pw.Document();
    final String date = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());

    final headers = ['Faculty Name', 'Status', 'Assigned Room'];
    final data = _currentDocs.map((doc) {
      final statusData = doc.data() as Map<String, dynamic>;
      return [
        statusData['facultyName'] ?? 'N/A',
        statusData['status'] ?? 'Unknown',
        statusData['assignedRoom'] ?? '--'
      ];
    }).toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Faculty Assignment Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(date),
                      ]
                  )
              ),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance.collection('facultyStatus');
    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Assignment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _printAssignmentList,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                _currentDocs = snapshot.data!.docs;
                var docs = _currentDocs;

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['facultyName']?.toLowerCase() ?? '';
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No faculty found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildFacultyAssignmentTile(data);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search Faculty...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String result) {
              setState(() {
                _statusFilter = result == 'All' ? null : result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'All', child: Text('All')),
              const PopupMenuItem<String>(value: 'Available', child: Text('Available')),
              const PopupMenuItem<String>(value: 'Unavailable', child: Text('Unavailable')),
              const PopupMenuItem<String>(value: 'Engaged', child: Text('Engaged')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyAssignmentTile(Map<String, dynamic> data) {
    final String name = data['facultyName'] ?? 'N/A';
    final String photoUrl = data['photoUrl'] ?? '';
    final String status = data['status'] ?? 'Unknown';

    Widget trailingWidget;

    switch (status) {
      case 'Available':
        trailingWidget = ElevatedButton(
          onPressed: () => _showAssignDutyDialog(context, data),
          child: const Text('Assign'),
        );
        break;
      case 'Engaged':
        final room = data['assignedRoom'] ?? 'N/A';
        trailingWidget = Chip(
          label: Text("Assigned: $room", style: const TextStyle(color: Color(0xFFB3AD03))),
          backgroundColor: const Color(0xFFFFFEB3),
        );
        break;
      default: // Unavailable
        trailingWidget = const Chip(
          label: Text("Unavailable", style: TextStyle(color: Color(0xFFEA0831))),
          backgroundColor: Color(0xFFFADDE2),
        );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? Text(name.isNotEmpty ? name.substring(0, 1) : 'F') : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Status: $status', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w500)),
        trailing: trailingWidget,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return const Color(0xFF01B634);
      case 'Unavailable': return const Color(0xFFEA0831);
      case 'Engaged': return const Color(0xFFB3AD03);
      default: return Colors.grey;
    }
  }
}
