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

  // Test Firebase connection
  testFirebaseConnection();

  runApp(CarCultureApp());
}

class OTPVerificationSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Make it full screen height
      child: DraggableScrollableSheet(
        initialChildSize: 0.6, // Starts at 50% of screen height
        minChildSize: 0.1, // Minimum size when dragged down
        maxChildSize: 0.6, // Allows full expansion
        expand: true, // Forces it to expand fully when dragged
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter OTP",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We have sent a verification code to your mobile number ****0898",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 60,
                        height: 60,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.grey[300]!, blurRadius: 5),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      print("Resend OTP");
                    },
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedCountry = "Malaysia";

  final List<Map<String, String>> countries = [
    {"name": "Malaysia", "code": "+60", "flag": "assets/images/malaysia_flag.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Container(
                    width: double.infinity,
                    height: 100,
                    alignment: Alignment.center,
                    child: Placeholder(),
                  ),

                  const SizedBox(height: 30),

                  // Country Dropdown & Mobile Number Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Aligns text field to the left
                    children: [
                      // Country Dropdown & Mobile Number Input
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCountry,
                                dropdownColor: Colors.grey[200],
                                items: countries.map((country) {
                                  return DropdownMenuItem<String>(
                                    value: country["name"],
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          country["flag"]!,
                                          width: 30,
                                          height: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(country["code"]!),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCountry = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: "Mobile Number",
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Add spacing before the button
                      const SizedBox(height: 20),

                      // Continue Button (Now properly placed below the text field)
                      SizedBox(
                        width: double.infinity, // Ensure the button is full width
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true, // Allows full-screen behavior
                              backgroundColor: Colors.transparent,
                              builder: (context) => OTPVerificationSheet(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Continue",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text.rich(
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
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> testFirebaseConnection() async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Add a test document to Firestore
    await firestore.collection('testCollection').add({
      'message': 'Firebase is connected!',
      'timestamp': DateTime.now(),
    });

    print("✅ Firebase is connected successfully!");
  } catch (e) {
    print("❌ Firebase connection failed: $e");
  }
}
