
//dialogue widget to handle adding teas to user lists or "Shelves" which are stored in the users "Cabinet". 
import 'package:flutter/material.dart';
import '../../services/user.dart'; 

class AddToCabinet extends StatefulWidget {
  final String teaId;
  const AddToCabinet({super.key, required this.teaId});

  @override
  State<AddToCabinet> createState() => _AddToCabinetState();
}

class _AddToCabinetState extends State<AddToCabinet> {
  final Set<String> disabledShelfIds = {};
  List<Map<String, dynamic>> userShelves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getShelves();
  }

  //function to load cabinet from backend
  Future<void> getShelves() async {
    final shelves = await fetchCabinet(); //handles the actual retrieval from backend
    if (shelves != null) {
      setState(() {
        userShelves = shelves;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        userShelves = [];
      });
    }
  }

  Future<void> _addTeaToShelf(String shelfId) async {
    final success = await addToShelf(widget.teaId, shelfId);
    if (success) {
      setState(() => disabledShelfIds.add(shelfId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tea added to shelf')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add tea')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Select Lists:'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            automaticallyImplyLeading: false,
          ),
          const Divider(),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      userShelves.map((shelf) {
                        final id = shelf['_id'];
                        final label = shelf['shelfLabel'];
                        final isDisabled = disabledShelfIds.contains(id);

                        return ElevatedButton(
                          onPressed:
                              isDisabled ? null : () => _addTeaToShelf(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDisabled ? Colors.grey[400] : null,
                          ),
                          child: Text(label),
                        );
                      }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
