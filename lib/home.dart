import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50),
    );
    _animation = Tween<double>(begin: 0, end: 350).animate(_controller);
  }

  void toggleDrawer() {
    setState(() {
      if (isDrawerOpen) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      isDrawerOpen = !isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // Drawer Background
          Container(
            width: 350,
            color: Colors.white,
            child: Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "CarCulture Menu",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text("Home"),
                  selected: true,
                  selectedTileColor: Colors.grey[300],
                  onTap: () {
                    toggleDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.forum),
                  title: Text("Forum"),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.directions_car),
                  title: Text("Car Clubs"),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.map),
                  title: Text("Maps"),
                  onTap: () {},
                ),
                Spacer(),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),

          AnimatedBuilder(

            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isDrawerOpen ? BorderRadius.circular(20) : BorderRadius.zero,
                    boxShadow: isDrawerOpen
                        ? [BoxShadow(color: Colors.black26, blurRadius: 5)]
                        : [],
                  ),
                  child: Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.grey[300],
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(isDrawerOpen ? Icons.menu : Icons.menu, color: Colors.black),
                        onPressed: toggleDrawer,
                      ),
                      title: Text(
                        "Home",
                        style: TextStyle(color: Colors.black),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          onPressed: () {},
                          icon: CircleAvatar(
                            backgroundColor: Colors.grey[700],
                            radius: 14,
                          ),
                        ),
                      ],
                    ),
                    body: Center(
                      child: Text(
                        user != null
                            ? "Welcome, ${user.displayName ?? user.email ?? user.phoneNumber}!"
                            : "Welcome to Home Screen!",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
