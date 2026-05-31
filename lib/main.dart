import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import jdid
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart'; // Import jdid

void main() async {
  // --- Setup darouri bach shared_preferences t-khdem f main ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- Check wach kyen token m-stoki ---
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // --- Ila kyen token sir l Dashboard, sinon Login ---
      home: initialToken != null
          ? DashboardScreen(token: initialToken!)
          : const LoginScreen(),
    );
  }
}
