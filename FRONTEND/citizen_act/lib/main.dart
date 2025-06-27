import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citizen Act',
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.red,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null &&
              args.containsKey('username') &&
              args.containsKey('userData')) {
            return MaterialPageRoute(
              builder: (context) => MainPage(
                username: args['username'] as String,
                userData: args['userData'] as Map<String, dynamic>,
              ),
            );
          } else {
            // Handle missing arguments gracefully
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                    child: Text('Error: Missing arguments for MainPage')),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
