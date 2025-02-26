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
            // 👇 Wraps the main content (logo + input box) inside Expanded to keep it centered
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Keeps content centered
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placeholder for Logo (Replace with actual logo)
                  Container(
                    width: 180,
                    height: 100,
                    color: Colors.grey[300], // Placeholder color
                    alignment: Alignment.center,
                    child: Text("Logo Here"),
                  ),

                  const SizedBox(height: 30),

                  // Country Dropdown & Mobile Number Input
                  Container(
                    width: double.infinity,
                    child: Row(
                      children: [
                        // Country Dropdown
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
                              isExpanded: false, // Prevents width expansion
                              items: countries.map((country) {
                                return DropdownMenuItem<String>(
                                  value: country["name"],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        country["flag"]!,
                                        width: 24,
                                        height: 16,
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

                        // Mobile Number Input
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
                  ),
                ],
              ),
            ),

            // ✅ This ensures the Terms & Conditions always remain at the bottom
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
