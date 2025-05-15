//this stores user created lists or "shelves" of teas
import 'package:flutter/material.dart';
import 'package:frontend/config/api.dart';
import '../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/pages/tea/details.dart';
import '../../services/teas.dart';

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
                  tooltip: 'Create New Shelf',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreateShelf(onCreated: loadCabinet),
                    );
                  },
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

                    return ShelfCard(
                      shelf: shelf,
                      onTeaTap: (tea) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeaDetails(tea: tea),
                          ),
                        );
                      },
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

class CreateShelf extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateShelf({super.key, required this.onCreated});

  @override
  State<CreateShelf> createState() => _CreateShelfState();
}

class _CreateShelfState extends State<CreateShelf> {
  final TextEditingController controller = TextEditingController();

  Future<void> _createShelf() async {
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

    if (res.statusCode == 200 || res.statusCode == 201) {
      widget.onCreated(); // Triggers reload
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
        ElevatedButton(onPressed: _createShelf, child: const Text('Create')),
      ],
    );
  }
}

class ShelfContentsDialog extends StatelessWidget {
  final String shelfLabel;
  final List<Map<String, dynamic>> teas;
  final void Function(Map<String, dynamic> tea) onTeaTap;

  const ShelfContentsDialog({
    super.key,
    required this.shelfLabel,
    required this.teas,
    required this.onTeaTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(shelfLabel),
      content:
          teas.isEmpty
              ? const Text('No teas in this shelf.')
              : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teas.length,
                  itemBuilder: (context, i) {
                    final tea = teas[i];
                    return ListTile(
                      title: Text(tea['name'] ?? 'Unnamed Tea'),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          Navigator.pop(context);
                          onTeaTap(tea); // Pass full tea doc
                        },
                      ),
                    );
                  },
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class ShelfCard extends StatelessWidget {
  final Map shelf;
  final void Function(Map<String, dynamic> teaId) onTeaTap;

  const ShelfCard({super.key, required this.shelf, required this.onTeaTap});

  void _showShelfContentsDialog(BuildContext context) {
    final teas = List<Map<String, dynamic>>.from(shelf['teas'] ?? []);
    final label = shelf['shelfLabel'] ?? 'Shelf';

    showDialog(
      context: context,
      builder:
          (context) => ShelfContentsDialog(
            shelfLabel: label,
            teas: teas,
            onTeaTap: (tea) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeaDetails(tea: tea)),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = shelf['shelfLabel'] ?? 'Shelf';
    final teaCount = (shelf['teas'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('$label ($teaCount)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showShelfContentsDialog(context),
      ),
    );
  }
}
