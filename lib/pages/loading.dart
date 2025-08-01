// lib/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firstproject/pages/wrapper.dart'; // Assurez-vous que le chemin est correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWrapper();
  }

  Future<void> _navigateToWrapper() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const wrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/OLEAONE.png'), // Votre image de fond ici
            ),
          ),
        ),
        // Le Container va prendre toute la taille disponible du Scaffold body

      ),
    );
  }
}