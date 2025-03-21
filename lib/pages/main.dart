import 'package:car_culture_fyp/pages/home_page.dart';
import 'package:car_culture_fyp/pages/login_page.dart';
import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:car_culture_fyp/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../auth/auth_cubit.dart';
import '../components/bottom_navigation_bar.dart';
import '../firebase_options.dart';
import '../home/home_cubit.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('short', CustomShortTimeAgoMessages());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => DatabaseProvider()),
        BlocProvider(
          create: (context) => AuthCubit(Provider.of<ThemeProvider>(context, listen: false)),
        ),
        BlocProvider(create: (context) => HomeCubit()),
      ],
      child: const CarCultureApp(),
    ),
  );
}

class CustomShortTimeAgoMessages extends timeago.EnMessages {
  @override
  String prefixAgo() => '';
  @override
  String suffixAgo() => '';
  @override
  String minutes(int minutes) => '${minutes}m';
  @override
  String hours(int hours) => '${hours}h';
  @override
  @override String aboutAnHour(int minutes) => '1h';

  String aDay(int hours) => '1d';
  @override
  String days(int days) => '${days}d';
  @override
  String weeks(int weeks) => '${weeks}w';
  @override
  String months(int months) => '${months}mo';
  @override
  String years(int years) => '${years}y';
}

class CarCultureApp extends StatelessWidget {
  const CarCultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      theme: themeProvider.themeData.copyWith(
        textTheme: themeProvider.themeData.textTheme.apply(
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => BottomNavWrapper(),
        '/login': (context) => LoginPage(),
      },
      home: LoginPage(),
    );
  }
}
