import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _message;
  bool _isLoading = false;
  Duration? _timeRemaining;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    setState(() {
      _timeRemaining = duration;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining!.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _timeRemaining = null;
        });
      } else {
        setState(() {
          _timeRemaining = _timeRemaining! - const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final resetDoc = FirebaseFirestore.instance
          .collection('passwordResetRequests')
          .doc(email);

      final docSnapshot = await resetDoc.get();
      final now = DateTime.now();

      if (docSnapshot.exists) {
        final lastSent =
        (docSnapshot.data()!['lastSent'] as Timestamp).toDate();
        final difference = now.difference(lastSent);

        if (difference.inHours < 24) {
          final remaining = Duration(hours: 24) - difference;
          _startCountdown(remaining);

          setState(() {
            _message =
            "Un lien a déjà été envoyé. Réessayez dans ${_formatDuration(remaining)}.";
            _isLoading = false;
          });
          return;
        }
      }

      // Envoi du lien
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await resetDoc.set({'lastSent': now});

      //chercher le mail dans la collection users et modifier le mot de passe

      //

      setState(() {
        _message = "Lien envoyé à $email.";
        _isLoading = false;
        _startCountdown(const Duration(hours: 24));
      });
    } catch (e) {
      setState(() {
        _message = "Erreur : ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _timeRemaining == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: const Color(0xFFB7482B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Entrez votre e-mail pour recevoir un lien de réinitialisation.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                val != null && val.contains('@') ? null : 'E-mail invalide',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading || !canSend
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    _sendResetEmail();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8AF3C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(canSend
                    ? 'Envoyer le lien'
                    : 'Réessayer dans ${_formatDuration(_timeRemaining!)}'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(
                  _message!,
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
