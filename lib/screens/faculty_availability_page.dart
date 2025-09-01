import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shiksha_sanchalan/models/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FacultyAvailabilityPage extends StatefulWidget {
  final UserModel currentUser;
  const FacultyAvailabilityPage({super.key, required this.currentUser});

  @override
  State<FacultyAvailabilityPage> createState() => _FacultyAvailabilityPageState();
}

class _FacultyAvailabilityPageState extends State<FacultyAvailabilityPage> {
  String _currentStatus = 'Unavailable';
  String _searchQuery = '';
  String? _statusFilter;
  List<QueryDocumentSnapshot> _currentDocs = []; // To hold the current list for printing

  @override
  void initState() {
    super.initState();
    if (widget.currentUser.role == 'faculty') {
      _fetchInitialStatus();
    }
  }

  Future<void> _fetchInitialStatus() async {
    final doc = await FirebaseFirestore.instance.collection('facultyStatus').doc(widget.currentUser.uid).get();
    if (doc.exists && doc.data() != null && mounted) {
      setState(() {
        _currentStatus = doc.data()!['status'] ?? 'Unavailable';
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _currentStatus = newStatus;
    });
    try {
      await FirebaseFirestore.instance.collection('facultyStatus').doc(widget.currentUser.uid).set({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'facultyName': widget.currentUser.name,
        'photoUrl': widget.currentUser.photoUrl,
        'uid': widget.currentUser.uid,
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    Query query = FirebaseFirestore.instance.collection('facultyStatus');
    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }
    return query.snapshots();
  }

  // Function to generate and print the PDF
  Future<void> _printStatusList() async {
    final pdf = pw.Document();
    final String date = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());

    final headers = ['Faculty Name', 'Status', 'Last Updated'];
    final data = _currentDocs.map((doc) {
      final statusData = doc.data() as Map<String, dynamic>;
      final timestamp = (statusData['lastUpdated'] as Timestamp?)?.toDate();
      final lastUpdated = timestamp != null ? DateFormat('h:mm a').format(timestamp) : 'N/A';
      return [statusData['facultyName'] ?? 'N/A', statusData['status'] ?? 'Unknown', lastUpdated];
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
                        pw.Text("Faculty Availability Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(date),
                      ]
                  )
              ),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(),
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

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.currentUser.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Availability"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _printStatusList, // Call the print function
          )
        ],
      ),
      body: Column(
        children: [
          if (isAdmin) _buildSearchBar(),
          if (!isAdmin) _buildFacultyStatusChanger(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Store the latest data for printing
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
                  return const Center(child: Text("No faculty found with the current filter."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildFacultyStatusTile(data);
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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

  Widget _buildFacultyStatusChanger() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        color: const Color(0xFFEDF0FF),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusChip('Available', const Color(0xFFD7FFE2), const Color(0xFF01B634)),
              _buildStatusChip('Unavailable', const Color(0xFFFADDE2), const Color(0xFFEA0831)),
              _buildStatusChip('Engaged', const Color(0xFFFFFEB3), const Color(0xFFB3AD03)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color bgColor, Color textColor) {
    bool isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _updateStatus(status);
      },
      backgroundColor: bgColor,
      selectedColor: bgColor,
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      shape: isSelected
          ? StadiumBorder(side: BorderSide(color: textColor, width: 1.5))
          : const StadiumBorder(),
      showCheckmark: false,
    );
  }

  Widget _buildFacultyStatusTile(Map<String, dynamic> data) {
    final String name = data['facultyName'] ?? 'N/A';
    final String photoUrl = data['photoUrl'] ?? '';
    final String status = data['status'] ?? 'Unknown';

    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'Available':
        statusColor = const Color(0xFF01B634);
        statusBgColor = const Color(0xFFD7FFE2);
        break;
      case 'Unavailable':
        statusColor = const Color(0xFFEA0831);
        statusBgColor = const Color(0xFFFADDE2);
        break;
      case 'Engaged':
        statusColor = const Color(0xFFB3AD03);
        statusBgColor = const Color(0xFFFFFEB3);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade200;
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
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Status: $status',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.message_outlined, color: Theme.of(context).primaryColor),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
