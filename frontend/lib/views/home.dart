//Main page.  contents are based on selected page from the drawer.
import 'package:flutter/material.dart';
import 'user/dashboard.dart'; // ✅ Import the ProfilePage
import '../config/theme.dart';
import './tea/search.dart'; 

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
      case 'Teas':
        return SearchPage();
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
