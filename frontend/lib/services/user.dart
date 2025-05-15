import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/api.dart';

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
    Uri.parse('$baseURI/api/user/'),
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
    Uri.parse('$baseURI/api/user/displayname'),
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

  final bytes = await image.readAsBytes(); // =
  final base64Image = base64Encode(bytes);

  final res = await http.post(
    Uri.parse('$baseURI/api/user/avatar/upload'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'base64Image': base64Image}),
  );

  if (res.statusCode != 200) {
    throw Exception('Upload failed');
  }
}

// Update review, if success return the new review to display
Future<Map<String, dynamic>> updateReview(
  String id,
  Map<String, dynamic> updatedFields,
) async {
  final token = await getJwtToken();
  if (token == null) throw Exception('No token');

  final res = await http.put(
    Uri.parse('$baseURI/api/user/reviews/$id'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(updatedFields),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to update review');
  }

  if (res.body.isEmpty) {
    throw Exception('Empty response from server');
  }

  final decoded = jsonDecode(res.body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  } else {
    throw Exception('Unexpected response format');
  }
}

//returns a list of shelves in the User's cabinet
Future<List<Map<String, dynamic>>?> fetchCabinet() async {
  final token = await getJwtToken();
  final response = await http.get(
    Uri.parse('$baseURI/api/user/shelves'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    print("fetchUserShelves failed with status ${response.statusCode}");
    return null;
  }
}



//add tea to shelf given teaID and shelfID
Future<bool> addToShelf(String teaId, String shelfId) async {
  final token = await getJwtToken();
  
  final response = await http.post(
    Uri.parse('$baseURI/api/user/shelves/$shelfId/teas'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'teaId': teaId}),
  );

  return response.statusCode == 200;
}