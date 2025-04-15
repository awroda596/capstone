import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'pages/login.dart';
import 'pages/home.dart';


void main() {
  runApp(MyApp());
}

//check if token is valid/exists, then goes to home, otherwise go to login page. 
class MyApp extends StatelessWidget {
  Future<bool> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return false;

    final response = await http.get(
      Uri.parse('https://127.0.0.1/user/profile'),
      headers: { 'Authorization': 'Bearer $token' },
    );

    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      home: FutureBuilder<bool>(
        future: checkToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return HomePage();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}