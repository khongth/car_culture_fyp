import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(CarCultureApp());
}

class OTPVerificationSheet extends StatefulWidget {
  @override
  _OTPVerificationSheetState createState() => _OTPVerificationSheetState();
}

class _OTPVerificationSheetState extends State<OTPVerificationSheet> {
  List<TextEditingController> controllers = List.generate(4, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
      } else {
        _verifyOTP();
      }
    }
  }

  void _onBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(focusNodes[index - 1]);
    }
  }

  void _verifyOTP() {
    String otp = controllers.map((controller) => controller.text).join();
    if (otp.length == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace) {
                            _onBackspace(controllers[index].text, index);
                          }
                        },
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) => _onChanged(value, index),
                          onSubmitted: (_) => _verifyOTP(),
                          onEditingComplete: () {
                            if (index == 3) _verifyOTP();
                          },
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Resend OTP Button
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
        ),
      ],
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

                  SizedBox(
                    child: Image.asset(
                      "assets/images/CarCultureLogo.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 100),

                  // Country Dropdown & Mobile Number Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Dropdown & Mobile Number Input
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
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
                                hintText: " Mobile Number",
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
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
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

