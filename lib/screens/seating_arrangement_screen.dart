import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// A helper class to hold the controllers for each branch's details.
class BranchDetails {
  final TextEditingController nameController;
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController skipController;

  BranchDetails()
      : nameController = TextEditingController(),
        startController = TextEditingController(),
        endController = TextEditingController(),
        skipController = TextEditingController();

  void dispose() {
    nameController.dispose();
    startController.dispose();
    endController.dispose();
    skipController.dispose();
  }
}

class SeatingArrangementScreen extends StatefulWidget {
  const SeatingArrangementScreen({super.key});

  @override
  State<SeatingArrangementScreen> createState() =>
      _SeatingArrangementScreenState();
}

class _SeatingArrangementScreenState extends State<SeatingArrangementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _roomController = TextEditingController();
  final _rowsController = TextEditingController();
  final _colsController = TextEditingController();

  final List<BranchDetails> _branchDetailsList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addBranch();
    _addBranch();
  }

  void _addBranch() {
    setState(() {
      _branchDetailsList.add(BranchDetails());
    });
  }

  void _removeBranch(int index) {
    setState(() {
      _branchDetailsList[index].dispose();
      _branchDetailsList.removeAt(index);
    });
  }

  // Orchestrator function for generating and downloading the PDF.
  Future<void> _onDownloadPdf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final pdfBytes = await _generatePdfBytes();
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Orchestrator function for generating and sharing the PDF.
  Future<void> _onSharePdf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final pdfBytes = await _generatePdfBytes();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/seating_plan.pdf");
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Seating Arrangement PDF for Room: ${_roomController.text}',
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $message"), backgroundColor: Colors.red),
    );
  }

  // Core logic to generate PDF bytes from form data.
  Future<Uint8List> _generatePdfBytes() async {
    // 1. Parse all inputs from controllers.
    final int rows = int.parse(_rowsController.text);
    final int cols = int.parse(_colsController.text);
    final int totalSeats = rows * cols;

    List<List<int>> studentLists = [];
    int totalStudents = 0;

    for (int i = 0; i < _branchDetailsList.length; i++) {
      final details = _branchDetailsList[i];
      final start = int.parse(details.startController.text);
      final end = int.parse(details.endController.text);
      final skipped = details.skipController.text
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .map(int.parse)
          .toSet();

      List<int> branchStudents = [];
      for (int j = start; j <= end; j++) {
        if (!skipped.contains(j)) {
          branchStudents.add(j);
        }
      }
      studentLists.add(branchStudents);
      totalStudents += branchStudents.length;
    }

    if (totalStudents > totalSeats) {
      throw Exception('Total students ($totalStudents) exceed total seats ($totalSeats).');
    }

    // 2. Create the seating arrangement grid with robust logic.
    List<List<String>> seatingGrid = List.generate(rows, (_) => List.filled(cols, ''));
    List<int> studentCounters = List.filled(studentLists.length, 0);
    int totalStudentsPlaced = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (totalStudentsPlaced >= totalStudents) break;

        int preferredBranchIndex = (r + c) % studentLists.length;
        int actualBranchIndex = -1;

        if (studentCounters[preferredBranchIndex] < studentLists[preferredBranchIndex].length) {
          actualBranchIndex = preferredBranchIndex;
        } else {
          for (int i = 0; i < studentLists.length; i++) {
            int nextBranchIndex = (preferredBranchIndex + 1 + i) % studentLists.length;
            if (studentCounters[nextBranchIndex] < studentLists[nextBranchIndex].length) {
              actualBranchIndex = nextBranchIndex;
              break;
            }
          }
        }

        if (actualBranchIndex != -1) {
          // **FIXED**: Safe substring logic to prevent range errors.
          final branchName = _branchDetailsList[actualBranchIndex].nameController.text;
          final branchCode = branchName.isNotEmpty
              ? branchName.substring(0, branchName.length > 3 ? 3 : branchName.length).toUpperCase()
              : "B${actualBranchIndex + 1}";
          seatingGrid[r][c] = "$branchCode: ${studentLists[actualBranchIndex][studentCounters[actualBranchIndex]]}";
          studentCounters[actualBranchIndex]++;
          totalStudentsPlaced++;
        }
      }
    }

    // 3. Generate the PDF document.
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "Seating Arrangement - Room: ${_roomController.text}",
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.center,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: List<List<String>>.generate(
                  seatingGrid.length,
                      (row) => List<String>.generate(
                    seatingGrid.isNotEmpty ? seatingGrid[0].length : 0,
                        (col) => seatingGrid[row][col],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Branch Legend:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...List.generate(_branchDetailsList.length, (index) {
                final branchName = _branchDetailsList[index].nameController.text;
                // **FIXED**: Safe substring logic for the legend as well.
                final branchCode = branchName.isNotEmpty ? branchName.substring(0, branchName.length > 3 ? 3 : branchName.length).toUpperCase() : "B${index + 1}";
                return pw.Text("$branchCode: ${branchName.isNotEmpty ? branchName : 'Branch ${index + 1}'}");
              }),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }


  @override
  void dispose() {
    _roomController.dispose();
    _rowsController.dispose();
    _colsController.dispose();
    for (final branch in _branchDetailsList) {
      branch.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seating Arrangement"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(controller: _roomController, hint: "Enter Room", isNumber: false),
              const SizedBox(height: 16),
              _buildTextField(controller: _rowsController, hint: "Enter Rows", isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _colsController, hint: "Enter Columns", isNumber: true),
              const SizedBox(height: 24),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _branchDetailsList.length,
                itemBuilder: (context, index) {
                  return _buildBranchInput(index);
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Group"),
                  onPressed: _addBranch,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onDownloadPdf,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text("Download"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _onSharePdf,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchInput(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text("Group ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(controller: _branchDetailsList[index].nameController, hint: "Branch Name"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _branchDetailsList[index].startController, hint: "Start Roll", isNumber: true)),
                    const SizedBox(width: 16),
                    // **FIXED**: Added validation for End Roll No.
                    Expanded(child: _buildTextField(
                      controller: _branchDetailsList[index].endController,
                      hint: "End Roll",
                      isNumber: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a value';
                        final start = int.tryParse(_branchDetailsList[index].startController.text);
                        final end = int.tryParse(value);
                        if (start != null && end != null && end < start) {
                          return 'End roll cannot be less than start';
                        }
                        return null;
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _branchDetailsList[index].skipController,
                  hint: "Roll numbers to skip (e.g., 10,15)",
                  isOptional: true,
                ),
              ],
            ),
          ),
        ),
        if (_branchDetailsList.length > 2)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _removeBranch(index),
              child: const Text("Remove Group", style: TextStyle(color: Colors.red)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isNumber = false, bool isOptional = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: validator ?? (value) {
        if (isOptional && (value == null || value.isEmpty)) {
          return null;
        }
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }
}
