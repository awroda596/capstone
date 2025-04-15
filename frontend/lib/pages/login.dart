import 'package:flutter/material.dart';
import '../services/auth.dart';
import 'home.dart';

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
  void _showRegistrationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return RegistrationDialog();
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            TextField(controller: _usernameController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text("Login")),
          ],
        ),
      ),
    );
  }
}

class RegistrationDialog extends StatefulWidget {
  @override
  _RegistrationDialogState createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String email = '';
  String password = '';
  String errorMessage = '';
  bool isSubmitting = false;
  bool isRegistered = false;

  Future<void> register() async {
    setState(() {
      isSubmitting = true;
      errorMessage = '';
    });

    final response = await http.post(
      Uri.parse('https://yourserver.com/register'), // <- Replace with your endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    setState(() {
      isSubmitting = false;
      if (response.statusCode == 200) {
        isRegistered = true;
      } else {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? 'Registration failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isRegistered ? "Success" : "Register"),
      content: isRegistered
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text("Registration complete!"),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: "Username"),
                    onChanged: (val) => username = val,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a username' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Email"),
                    onChanged: (val) => email = val,
                    validator: (val) =>
                        val == null || !val.contains('@') ? 'Enter valid email' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Password"),
                    obscureText: true,
                    onChanged: (val) => password = val,
                    validator: (val) =>
                        val == null || val.length < 6 ? 'Min 6 characters' : null,
                  ),
                  SizedBox(height: 12),
                  if (errorMessage.isNotEmpty)
                    Text(errorMessage, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              AuthRegister();
                            }
                          },
                    child: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text("Submit"),
                  ),
                ],
              ),
            ),
      actions: [
        if (isRegistered)
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        if (!isRegistered)
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }
}