import 'package:flutter/material.dart';
import '../../services/auth.dart';
import '../home.dart';
import 'register.dart';
import '../../config/theme.dart'; 
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  void _login() async {
    final success = await AuthLogin(
      _usernameController.text,
      _passwordController.text,
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() => _error = "Invalid login");
    }
  }

void _showRegistrationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Builder(
        builder: (context) {
          return Theme(
            data: Theme.of(context).copyWith(
              textTheme: appTheme.textTheme,
              inputDecorationTheme: appTheme.inputDecorationTheme,
              elevatedButtonTheme: appTheme.elevatedButtonTheme,
            ),
            child: RegistrationDialog(),
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Spill the Tea")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text("Login")),
            TextButton(
              onPressed: _showRegistrationDialog,
              child: Text(
                "Don't have an account? Register",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// register pop up dialog

