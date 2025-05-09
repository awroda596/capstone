import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api.dart'; 

//login.  On logging in successfully, the JWT token is stored in shared preferences.
Future<bool> AuthLogin(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseURI/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );

  if (response.statusCode == 200) {
    final token = jsonDecode(response.body)['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  
    return true;
  } else {
    return false;
  }
}

//registration.  On registering successfully, the JWT token is stored in shared preferences.
Future<Map<String, dynamic>> AuthRegister(String username, String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseURI/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return { 'success': true, 'message': 'Registered successfully' };
  } else {
    final body = jsonDecode(response.body);
    return {
      'success': false,
      'message': body['message'] ?? 'Unknown registration error'
    };
  }
}