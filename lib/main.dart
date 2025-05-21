import 'package:election_app/screens/login_screen.dart';
import 'package:election_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      initialRoute: isLoggedIn ? '/voters' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/voters': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}