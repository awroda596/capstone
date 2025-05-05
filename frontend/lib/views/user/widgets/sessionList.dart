import 'package:flutter/material.dart';
import '../../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TeaLogList extends StatefulWidget {
  const TeaLogList({super.key});
  @override
  State<TeaLogList> createState() => _TeaLogListState();
}

class _TeaLogListState extends State<TeaLogList> {
  List<dynamic> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }
  void _showCreateDialog() {
  final teaNameController = TextEditingController();
  final vendorController = TextEditingController();
  final sessionTextController = TextEditingController();
  final flavorNotesController = TextEditingController();
  final weightController = TextEditingController();
  final volumeController = TextEditingController();
  final tempController = TextEditingController();
  final timeController = TextEditingController();

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('New Tea Session'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: teaNameController,
                  decoration: const InputDecoration(labelText: 'Tea Name'),
                ),
                TextField(
                  controller: vendorController,
                  decoration: const InputDecoration(labelText: 'Tea Vendor'),
                ),
                TextField(
                  controller: sessionTextController,
                  decoration: const InputDecoration(labelText: 'Session Notes'),
                  maxLines: 4,
                ),
                TextField(
                  controller: flavorNotesController,
                  decoration: const InputDecoration(labelText: 'Flavor Notes'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (g)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: volumeController,
                        decoration: const InputDecoration(
                          labelText: 'Volume (ml)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tempController,
                        decoration: const InputDecoration(
                          labelText: 'Temp (°C)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: 'Time'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (sessionTextController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session Notes are required')),
                  );
                  return;
                }

                final newSession = {
                  'teaName': teaNameController.text.trim(),
                  'teaVendor': vendorController.text.trim(),
                  'sessionText': sessionTextController.text.trim(),
                  'flavorNotes': flavorNotesController.text.trim(),
                  'brewWeight': weightController.text.trim(),
                  'brewVolume': volumeController.text.trim(),
                  'brewTemp': tempController.text.trim(),
                  'brewTime': timeController.text.trim(),
                };

                final token = await getJwtToken();
                final res = await http.post(
                  Uri.parse('http://localhost:3000/api/user/sessions'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(newSession),
                );

                if (res.statusCode == 200 || res.statusCode == 201) {
                  Navigator.pop(context);
                  fetchSessions(); // refresh list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create session')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
  );
}

  Future<void> fetchSessions() async {
    final token = await getJwtToken();
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/user/sessions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        sessions = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  void _showSessionDialog(Map<String, dynamic> session) {
    final created =
        DateTime.tryParse(session['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy').format(created);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['teaName'] ?? 'Unnamed',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session['teaVendor'] ?? 'Unknown Vendor',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(session),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: $formattedDate',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (session['sessionText'] != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(session['sessionText']),
                      ),
                    const SizedBox(height: 12),
                    if (session['flavorNotes'] != null)
                      Text(
                        "Flavor notes: ${session['flavorNotes']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 8),
                    if (session['brewWeight'] != null ||
                        session['brewVolume'] != null ||
                        session['brewTemp'] != null)
                      Text(
                        '${session['brewWeight'] ?? '?'}g, '
                        '${session['brewVolume'] ?? '?'}ml, '
                        '${session['brewTemp'] ?? '?'}°C',
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (session['brewTime'] != null)
                      Text(
                        'Time: ${session['brewTime']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showEditDialog(Map<String, dynamic> session) {
    final id = session['_id'];
    final sessionTextController = TextEditingController(
      text: session['sessionText'],
    );
    final flavorNotesController = TextEditingController(
      text: session['flavorNotes'],
    );
    final weightController = TextEditingController(
      text: session['brewWeight']?.toString() ?? '',
    );
    final volumeController = TextEditingController(
      text: session['brewVolume']?.toString() ?? '',
    );
    final tempController = TextEditingController(
      text: session['brewTemp']?.toString() ?? '',
    );
    final timeController = TextEditingController(
      text: session['brewTime'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Session'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text('Tea: ${session['teaName'] ?? 'Unnamed'}'),
                  Text('Vendor: ${session['teaVendor'] ?? 'Unknown'}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sessionTextController,
                    decoration: const InputDecoration(
                      labelText: 'Session Notes',
                    ),
                    maxLines: 4,
                  ),
                  TextField(
                    controller: flavorNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Flavor Notes',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: 'Weight (g)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: volumeController,
                          decoration: const InputDecoration(
                            labelText: 'Volume (ml)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tempController,
                          decoration: const InputDecoration(
                            labelText: 'Temp (°C)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(labelText: 'Time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final token = await getJwtToken();
                  await http.delete(
                    Uri.parse('http://localhost:3000/api/user/sessions/$id'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                  );
                  Navigator.pop(context); // close edit
                  Navigator.pop(context); // close view
                  fetchSessions(); // reload
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final token = await getJwtToken();
                  final updated = {
                    'sessionText': sessionTextController.text,
                    'flavorNotes': flavorNotesController.text,
                    'brewWeight': weightController.text,
                    'brewVolume': volumeController.text,
                    'brewTemp': tempController.text,
                    'brewTime': timeController.text,
                  };

                  await http.put(
                    Uri.parse('http://localhost:3000/api/user/sessions/$id'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(updated),
                  );
                  Navigator.pop(context); // close edit
                  Navigator.pop(context); // close view
                  fetchSessions(); // reload
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Tea Log",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showCreateDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                height: 400, // scrollable region
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final date =
                        DateTime.tryParse(session['createdAt'] ?? '') ??
                        DateTime.now();
                    final dateStr = DateFormat('dd MMM yyyy').format(date);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(session['teaName'] ?? 'Unnamed'),
                        subtitle: Text(session['teaVendor'] ?? 'Unknown'),
                        trailing: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _showSessionDialog(session),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

