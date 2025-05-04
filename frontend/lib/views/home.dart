//Main page.  contents are based on selected page from the drawer.
import 'package:flutter/material.dart';
import 'profile.dart'; // ✅ Import the ProfilePage
import '../config/theme.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPage = 'Home';

  Widget _buildPage() {
    switch (selectedPage) {
      case 'Profile':
        return ProfilePage(); 
      case 'Teas':
        return Center(child: Text('Teas Page'));
      default:
        return Center(child: Text('Home Page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tea Explorer'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Welcome!'),
              decoration: BoxDecoration(color: Matcha),
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                setState(() => selectedPage = 'Profile');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Teas'),
              onTap: () {
                setState(() => selectedPage = 'Teas');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Timer'),
              onTap: () {
                setState(() => selectedPage = 'Teas');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _buildPage(),
    );
  }
}
