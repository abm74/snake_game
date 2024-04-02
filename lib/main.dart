import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/firebase_options.dart';
import 'package:snake_game/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false, home: const HomePage());
  }
}
