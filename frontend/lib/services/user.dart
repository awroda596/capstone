import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

//split off for ease of use
Future<String?> getJwtToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  return token; 
}

//get basic user data (username, and user image)
Future<Map<String, dynamic>> getUserData() async {
  final token = await getJwtToken();
  if (token == null) throw Exception('JWT token not found');

  final res = await http.get(
    Uri.parse('http://localhost:3000/api/user/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (res.statusCode != 200) throw Exception('Failed to load user');
  return json.decode(res.body);
}


Future<void> updateDisplayName(String newName) async {
  print("update"); 
  final token = await getJwtToken();
  if (token == null) throw Exception('No token');
  final res = await http.post(
    Uri.parse('http://localhost:3000/api/user/displayname'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: '{"displayname": "$newName"}',
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to update display name');
  }
}

Future<void> updateAvatar(XFile image) async {
  final token = await getJwtToken();
  if (token == null) throw Exception('No token');

  final bytes = await image.readAsBytes();  // ✅ works on all platforms
  final base64Image = base64Encode(bytes);

  final res = await http.post(
    Uri.parse('http://localhost:3000/api/user/avatar/upload'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({ 'base64Image': base64Image }),
  );

  if (res.statusCode != 200) {
    throw Exception('Upload failed');
  }
}


Future<void> updateReview(String id, Map<String, dynamic> updatedFields) async {
  final token = await getJwtToken();
  if (token == null) throw Exception('No token');

  final res = await http.put(
    Uri.parse('http://localhost:3000/api/user/reviews/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(updatedFields),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to update review');
  }
}