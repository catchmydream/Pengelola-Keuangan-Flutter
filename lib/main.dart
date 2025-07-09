import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import sqflite_common_ffi
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // Inisialisasi sqflite_common_ffi untuk platform desktop (Windows)
  databaseFactory = databaseFactoryFfi;  //supaya konek ke database

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kas App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return HomeScreen(userId: args);
        },
      },
    );
  }
}
