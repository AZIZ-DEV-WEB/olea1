import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authenticate.dart';

class EmailVerificationPage extends StatefulWidget {
  final String username;
  final String department;
  final String poste;
  final String email;


  const EmailVerificationPage({
    super.key,
    required this.username,
    required this.department,
    required this.poste,
    required this.email, // <--- à ajouter
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isVerified = false;
  bool isResending = false;
  bool firestoreSaved = false;
  DateTime? _lastSentTime;
  bool _canResend = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkVerificationLoop();
    _setInitialResendTimer(); // <-- important
    _loadLastSentTime();
  }

  Future<void> _setInitialResendTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('lastVerificationEmailSent', now.toIso8601String());

    setState(() {
      _canResend = true;
    });

    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }



  Future<void> _loadLastSentTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentStr = prefs.getString('lastVerificationEmailSent');
    if (lastSentStr != null) {
      _lastSentTime = DateTime.tryParse(lastSentStr);
      if (_lastSentTime != null &&
          DateTime.now().difference(_lastSentTime!).inHours < 24) {
        setState(() {
          _canResend = false;
        });
        // Re-enable the button after the remaining time
        final remaining = Duration(
          hours: 24 - DateTime.now().difference(_lastSentTime!).inHours,
        );
        Future.delayed(remaining, () {
          setState(() {
            _canResend = true;
          });
        });
      }
    }
  }

  void _checkVerificationLoop() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      if (user.emailVerified) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists && !firestoreSaved) {
          await docRef.update({'emailVerified': true});
          firestoreSaved = true;
        }

        timer.cancel();
        setState(() {
          isVerified = true;
        });

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const authenticate()),
          );
        }
      }
    });
  }


  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      isResending = true;
      _canResend = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastVerificationEmailSent', now.toIso8601String());

      _lastSentTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lien de vérification renvoyé.")),
      );

      // Réactiver le bouton après 24h
      Future.delayed(const Duration(hours: 24), () {
        setState(() {
          _canResend = true;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
      setState(() {
        _canResend = true; // Réactivation en cas d'erreur
      });
    } finally {
      setState(() => isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8AF3C), // orange OLEA
        title: const Text(
          'Vérification de l\'email',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: isVerified
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 100),
              SizedBox(height: 24),
              Text(
                'Email vérifié !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Redirection en cours...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined,
                  size: 100, color: Color(0xFFB7482B)), // rouge OLEA
              const SizedBox(height: 24),
              const Text(
                'Un lien de vérification a été envoyé à votre email.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez vérifier votre boîte de réception ou vos spams.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: screenWidth * 0.7,
                height: 50,
                child:
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: (_canResend && !isResending) ? _resendVerificationEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8AF3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: isResending
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    _canResend
                        ? 'Renvoyer le lien'
                        : 'Lien déjà envoyé (attendre 24h)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const authenticate()),
                  );
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFFB7482B)),
                label: const Text(
                  'Retour',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB7482B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
