import 'package:flutter/material.dart';
import '../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/api.dart'; 
import 'package:frontend/config/api.dart'; 
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
                print("Posting session to ${baseURI}/api/user/sessions\n"); 
                final token = await getJwtToken();
                final res = await http.post(
                  Uri.parse('${baseURI}/api/user/sessions'),
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


//move later to like auth or something.  refactor to deal with setState
  Future<void> fetchSessions() async {
    final token = await getJwtToken();
    final response = await http.get(
      Uri.parse('$baseURI/api/user/sessions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        sessions = json.decode(response.body);
        sessions = sessions.reversed.toList(); //reverse for latest to  oldest
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
                        'brewed ${session['brewWeight'] ?? '?'}g tea with '
                        '${session['brewVolume'] ?? '?'}ml water at '
                        '${session['brewTemp'] ?? '?'}°C for',
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
                    Uri.parse('$baseURI/api/user/sessions/$id'),
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
                    Uri.parse('$baseURI/api/user/sessions/$id'),
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

class ViewSessionDialog extends StatefulWidget {
  final Map<String, dynamic> session;
  final VoidCallback onRefresh;
  final Function(Map<String, dynamic>)? onSessionUpdated; 

  const ViewSessionDialog({
    super.key,
    required this.session,
    required this.onRefresh,
    this.onSessionUpdated,
  });

  @override
  State<ViewSessionDialog> createState() => _ViewSessionDialogState();
}


class _ViewSessionDialogState extends State<ViewSessionDialog> {
  late Map<String, dynamic> session;
  bool isEditing = false;
  String? errorMessage;
  late TextEditingController reviewTextController;
  late TextEditingController flavorNotesController;
  late TextEditingController ratingController;

  @override
  void initState() {
    super.initState();
    session = Map<String, dynamic>.from(widget.session);
    reviewTextController = TextEditingController(text: session['reviewText']);
    flavorNotesController = TextEditingController(text: session['flavorNotes']);
    ratingController = TextEditingController(
      text: session['rating']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    reviewTextController.dispose();
    flavorNotesController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final rating = int.tryParse(ratingController.text);
    if (rating == null || rating < 0 || rating > 10) {
      setState(() {
        errorMessage = 'Rating must be between 0 and 10';
      });
      return;
    }

    try {
      final updated = await updateReview(session['_id'], {
        'reviewText': reviewTextController.text,
        'flavorNotes': flavorNotesController.text,
        'rating': rating,
      });

      setState(() {
        session = updated;
        isEditing = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update review. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    icon: Icon(isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() => isEditing = !isEditing);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Review Text
              isEditing
                  ? TextField(
                    controller: reviewTextController,
                    decoration: const InputDecoration(labelText: 'Review'),
                    maxLines: 4,
                  )
                  : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session['reviewText'] ?? 'No review provided.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              const SizedBox(height: 12),

              // Flavor Notes
              isEditing
                  ? TextField(
                    controller: flavorNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Flavor Notes',
                    ),
                  )
                  : Text(
                    'Flavor Notes: ${session['flavorNotes'] ?? 'None'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              const SizedBox(height: 12),

              // Rating
              isEditing
                  ? TextField(
                    controller: ratingController,
                    decoration: const InputDecoration(
                      labelText: 'Rating (0–10)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  )
                  : Text(
                    'Rating: ${session['rating'] ?? '?'} / 10',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEditing)
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  if (!isEditing)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}