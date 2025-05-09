//Main page.  contents are based on selected page from the drawer,
import 'package:flutter/material.dart';
import 'user/dashboard.dart'; // ✅ Import the ProfilePage
import '../config/theme.dart';
import 'tea/search.dart';
import 'auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/timer/timerpage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPage = 'Dashboard';

  Widget _buildPage() {
    switch (selectedPage) {
      case 'Dashboard': //user Dash/profile
        return Dashboard();
      case 'Search':
        return SearchPage();
      case 'Timer':
        return TimerPage();

      default:
        return Center(child: Center( child: Text('Home Page')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // or prefs.clear()

    // Avoid race conditions with backend-auth logic on resume
    await Future.delayed(Duration(milliseconds: 100));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center( child:Text(selectedPage))),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Dashboard'),
              onTap: () {
                setState(() => selectedPage = 'Dashboard');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Teas'),
              onTap: () {
                setState(() => selectedPage = 'Search');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Timer'),
              onTap: () {
                setState(() => selectedPage = 'Timer');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context); // close drawer first
                _logout(); // call logout
                print('Logout tapped'); // debug
              },
            ),
          ],
        ),
      ),
      body: _buildPage(),
    );
  }
}
