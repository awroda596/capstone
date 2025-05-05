import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/user.dart';


class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  late TextEditingController _controller;
  String? _currentName;
  String? _profileImageUrl;
  String? _createdDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await getUserData();
      setState(() {
        _currentName = data["displayname"];
        _profileImageUrl = data['avatar'];
        _createdDate = data['created'];
        _controller = TextEditingController(text: _currentName);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load user data')));
    }
  }

  Future<void> _updateDisplayName() async {
    try {
      await updateDisplayName(_controller.text);
      setState(() {
        _currentName = _controller.text;
      });
      Navigator.of(context).pop();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update display name')),
      );
    }
  }

  Future<void> pickNewAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        print("update");
        await updateAvatar(pickedFile); // ✅ Pass XFile directly
        print("update");
        setState(() {
          _profileImageUrl =
              _profileImageUrl == null
                  ? ''
                  : _profileImageUrl! +
                      '?${DateTime.now().millisecondsSinceEpoch}';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')),
        );
      }
    }
  }

  void _openEditDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Display Name"),
            content: TextField(
              controller: _controller,
              maxLength: 20,
              decoration: const InputDecoration(
                hintText: "Enter new display name",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _updateDisplayName,
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const CircularProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickNewAvatar,
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child:
                    (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40)
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Display Name: $_currentName",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _openEditDialog,
                        icon: const Icon(Icons.edit_square),
                        tooltip: "Edit display name",
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_createdDate != null)
                    Text(
                      "Joined: ${_createdDate!.split('T').first}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}