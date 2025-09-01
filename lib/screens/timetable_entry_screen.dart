import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// A helper class to store the date and time for each subject.
class SubjectDateTime {
  DateTime? date;
  TimeOfDay? time;

  SubjectDateTime({this.date, this.time});
}

class TimetableEntryScreen extends StatefulWidget {
  final int semesterNumber;
  final Map<String, dynamic> branchData;
  final DateTime? commonDate;
  final TimeOfDay? commonTime;

  const TimetableEntryScreen({
    super.key,
    required this.semesterNumber,
    required this.branchData,
    this.commonDate,
    this.commonTime,
  });

  @override
  State<TimetableEntryScreen> createState() => _TimetableEntryScreenState();
}

class _TimetableEntryScreenState extends State<TimetableEntryScreen> {
  late Map<String, SubjectDateTime> _subjectData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final subjects = widget.branchData['subjects'] as List<String>;
    _subjectData = {
      for (var subject in subjects)
        subject: SubjectDateTime(
          date: widget.commonDate,
          time: widget.commonTime,
        )
    };
  }

  // Pickers for individual subjects
  Future<void> _pickDate(String subject) async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: _subjectData[subject]?.date ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (pickedDate != null) {
      setState(() => _subjectData[subject]!.date = pickedDate);
    }
  }

  Future<void> _pickTime(String subject) async {
    final pickedTime = await showTimePicker(
        context: context,
        initialTime: _subjectData[subject]?.time ?? TimeOfDay.now());
    if (pickedTime != null) {
      setState(() => _subjectData[subject]!.time = pickedTime);
    }
  }

  // PDF Generation and Handling
  Future<void> _onDownloadPdf() async {
    setState(() { _isLoading = true; });
    try {
      final pdfBytes = await _generatePdfBytes();
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _onSharePdf() async {
    setState(() { _isLoading = true; });
    try {
      final pdfBytes = await _generatePdfBytes();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/timetable.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Exam Timetable');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $message"), backgroundColor: Colors.red));
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final List<List<String>> tableData = [
      ['Subject', 'Date', 'Time']
    ];
    _subjectData.forEach((subject, dateTime) {
      final dateStr = dateTime.date != null
          ? DateFormat('EEE, MMM d, yyyy').format(dateTime.date!)
          : 'Not Set';
      final timeStr =
      dateTime.time != null ? dateTime.time!.format(context) : 'Not Set';
      tableData.add([subject, dateStr, timeStr]);
    });

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
                level: 0,
                child: pw.Text(
                    "Exam Timetable - Semester ${widget.semesterNumber}",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Text("Branch: ${widget.branchData['name']}",
                style:
                pw.TextStyle(fontSize: 18, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                data: tableData),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.branchData['subjects'] as List<String>;
    final branchName = widget.branchData['name'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(branchName),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final subjectDateTime = _subjectData[subject]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateTimePicker(
                              label: 'Exam Date',
                              value: subjectDateTime.date != null
                                  ? DateFormat.yMMMd()
                                  .format(subjectDateTime.date!)
                                  : 'Select Date',
                              onTap: () => _pickDate(subject),
                              icon: Icons.calendar_today_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateTimePicker(
                              label: 'Exam Time',
                              value: subjectDateTime.time?.format(context) ??
                                  'Select Time',
                              onTap: () => _pickTime(subject),
                              icon: Icons.access_time_outlined)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Bottom Action Buttons
      bottomSheet: _isLoading
          ? const LinearProgressIndicator()
          : Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _onDownloadPdf,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text("Download"))),
            const SizedBox(width: 16),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: _onSharePdf,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text("Share"))),
          ],
        ),
      ),
    );
  }

  // Helper widget for date/time picker fields
  Widget _buildDateTimePicker(
      {required String label,
        required String value,
        required VoidCallback onTap,
        IconData? icon}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        child: Text(value),
      ),
    );
  }
}
