import 'package:flutter/material.dart';

void main() {
  runApp(CarCultureApp());
}

class CarCultureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Logo & Tagline
                Text(
                  'CarCulture.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'drive together, connect forever',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Courier',
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                // Mobile Number Input
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/malaysia_flag.png', // Ensure flag image is in assets
                            width: 24,
                            height: 16,
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "mobile number",
                          border: UnderlineInputBorder(),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Terms and Privacy
                Text.rich(
                  TextSpan(
                    text: "By continuing you agree to CarCulture.\n",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Terms of Use",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: " & "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Bottom Bar
                Container(
                  width: double.infinity,
                  height: 5,
                  color: Colors.black,
                ),
              ],
            ),
          ),

          // Chat Button
          Positioned(
            top: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.grey[300],
              mini: true,
              onPressed: () {},
              child: Icon(Icons.chat, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
