import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(), // Start with LoginScreen first
  ));
}


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
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
                //backgroundImage: AssetImage(" "),
                radius: 14,
              )
          ),
        ],
        //automaticallyImplyLeading: false, --disable back button
      ),

      drawer: Drawer(
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

            //Navigation Items
            ListTile(
              leading: Icon(Icons.home),
              title: Text("Home"),
              selected: true,
              selectedTileColor: Colors.grey[300],
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.forum),
              title: Text("Forum"),
              onTap: () {
                print("Forum tapped");
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text("Car clubs"),
              onTap: () {
                print("Car clubs tapped");
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text("Maps"),
              onTap: () {
                print("Maps tapped");
              },
            ),
          ],
        ),
      ),

      body: Center(
        child: Text(
          "Welcome to Home Screen!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}