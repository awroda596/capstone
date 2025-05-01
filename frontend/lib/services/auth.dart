import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



Future<bool> AuthLogin(String username, String password) async {
  final response = await http.post(
    Uri.parse('https://127.0.0.1/auth/login'),
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

Future<bool> AuthRegister(String username, String email, String password) async {
  final response = await http.post(
    Uri.parse('https://127.0.0.1/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}