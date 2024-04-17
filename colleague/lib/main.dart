import 'package:flutter/material.dart';
import 'widgets/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Baker',
        ),
        primaryTextTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Baker'),
        primaryColor: const Color(0xFF0A0E21),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        appBarTheme: const AppBarTheme(color: Colors.purple),
      ),
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}