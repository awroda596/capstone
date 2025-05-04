import 'package:flutter/material.dart';
import 'package:frontend/config/theme.dart';
import '../../services/auth.dart';
import '../home.dart';


//register dialogue box that pops up

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

    try {
      final result = await AuthRegister(username, email, password);

      if (result['success']) {
        setState(() {
          isSubmitting = false;
          isRegistered = true;
        });
      } else {
        final message =
            result['message'] ?? 'Registration failed. Please try again.';
        setState(() {
          isSubmitting = false;
          errorMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
        errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Text(isRegistered ? "Success" : "Register"),
      content:
          isRegistered
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                  ),
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
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? 'Enter a username'
                                  : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Email"),
                      onChanged: (val) => email = val,
                      validator:
                          (val) =>
                              val == null || !val.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Password"),
                      obscureText: true,
                      onChanged: (val) => password = val,
                      validator:
                          (val) =>
                              val == null || val.length < 6
                                  ? 'Min 6 characters'
                                  : null,
                    ),
                    SizedBox(height: 12),
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          isSubmitting
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  register();
                                }
                              },
                      child:
                          isSubmitting
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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