import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../pages/home_page.dart';
import 'drawer.dart'; // Your drawer widget

class BottomNavWrapper extends StatefulWidget {
  final int initialIndex;
  BottomNavWrapper({super.key, this.initialIndex = 0});

  @override
  _BottomNavWrapperState createState() => _BottomNavWrapperState();
}

class _BottomNavWrapperState extends State<BottomNavWrapper> {
  late int _currentIndex;

  final List<Widget> _pages = [
    HomePage(),
    HomePage(),
    HomePage(),
    HomePage(),
    HomePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),  // Your drawer widget
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          "Car Culture",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _pages[_currentIndex], // Display selected page content
      ),
      extendBody: true, // Allow content to extend behind the drawer
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade500, // Set border color
              width: 0.5, // Set border width
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.category),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.game),
              label: 'Car Clubs',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.location),
              label: 'Maps',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyBold.profile),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
