
import 'package:car_culture_fyp/pages/login_page.dart';
import 'package:car_culture_fyp/themes/light_mode.dart';
import 'package:car_culture_fyp/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../auth/auth_cubit.dart';
import '../components/bottom_navigation_bar.dart';
import '../firebase_options.dart';
import '../home/home_cubit.dart';
import 'home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        BlocProvider(
          create: (context) => AuthCubit(Provider.of<ThemeProvider>(context, listen: false)), // ✅ Pass ThemeProvider to AuthCubit
        ),
        BlocProvider(create: (context) => HomeCubit()),
      ],
      child: CarCultureApp(),
    ),
  );
}

class CarCultureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => BottomNavWrapper(),
        '/login': (context) => LoginPage(),
      },
      home: LoginPage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
