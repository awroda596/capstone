import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';


import 'pages/login.dart';
import 'pages/home.dart';

//override the bad certificate since we are using self signed certificate.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = DevHttpOverrides(); // Set the global HttpOverrides
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