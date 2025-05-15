import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'config/theme.dart';
import 'pages/auth/login.dart';
import 'pages/home.dart';
import 'package:frontend/config/api.dart'; 

//colors (theming)

//For dev puprposes, for  testing https: 
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
  
  //get token if it's available.  
  Future<bool> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print("have token"); 
  

    if (token == null) return false;
    final response = await http.get(
      Uri.parse('$baseURI/auth'),
      headers: { 'Authorization': 'Bearer $token' },
    );

    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steep Seek',
      theme: appTheme, //defined in theme in config
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