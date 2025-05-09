//this stores user created lists or "shelves" of teas 
import 'package:flutter/material.dart';
import 'package:frontend/config/api.dart';
import '../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeaCabinetList extends StatefulWidget {
  const TeaCabinetList({super.key});
  @override
  State<TeaCabinetList> createState() => _TeaCabinetListState();
}

class _TeaCabinetListState extends State<TeaCabinetList> {
  List<dynamic> shelves = [];
  bool isLoading = true;
  bool isEmpty = false;

  @override
  void initState() {
    super.initState();
    loadCabinet();
  }

  Future<void> loadCabinet() async {
    final fetchedShelves = await fetchCabinet();
    if (fetchedShelves != null) {
      setState(() {
        shelves = fetchedShelves;
        isLoading = false;
        isEmpty = fetchedShelves.isEmpty;
      });
    } else {
      setState(() {
        isLoading = false;
        isEmpty = true;
      });
    }
  }

  //need to separate as own widget.  
  void _showCreateShelfDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Shelf'),
            content: TextField(
              controller: controller,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Shelf Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final token = await getJwtToken();
                  final label = controller.text.trim();
                  if (label.isEmpty) return;

                  final res = await http.post(
                    Uri.parse('$baseURI/api/user/shelves'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'shelfLabel': label}),
                  );

                  Navigator.pop(context);
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    loadCabinet(); //reload from backend.
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  //also need to separate as a w
  void _showShelfContentsDialog(Map shelf) {
    final teas = List<String>.from(shelf['teas'] ?? []);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(shelf['shelfLabel'] ?? 'Shelf'),
            content:
                teas.isEmpty
                    ? const Text('No teas in this shelf.')
                    : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: teas.length,
                        itemBuilder: (_, i) => ListTile(title: Text(teas[i])),
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
            // Header + +
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tea Cabinet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showCreateShelfDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const CircularProgressIndicator()
            else if (isEmpty)
              const Text("You haven't added any shelves yet.")
            else
            Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: shelves.length,
              itemBuilder: (context, index) {
                final shelf = shelves[index];
                final label = shelf['shelfLabel'] ?? 'Unnamed Shelf';
                final teaCount = (shelf['teas'] as List?)?.length ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('$label ($teaCount)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showShelfContentsDialog(shelf),
                  ),
                );
              },
            ),)
          ],
        ),
      ),
    );
  }
}
