import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/form_screen.dart';
import 'ui/screens/resultados_screen.dart';
import 'ui/screens/pokemon_parceiro_screen.dart'; // NOVO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FormApp());
}

class FormApp extends StatelessWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Form App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/form': (context) => const FormScreen(),
        '/results': (context) => const ResultadosScreen(),
        '/parceiro': (context) => const PokemonParceiroScreen(), // NOVO
      },
    );
  }
}