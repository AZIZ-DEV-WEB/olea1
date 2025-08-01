import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/authenticate/register.dart';
import 'package:firstproject/pages/authenticate/verificationEmail.dart';
import 'package:firstproject/pages/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/user.dart';
import '../../services/auth.dart';
import '../user/UserHomePage.dart';
import 'forgot_password.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  SignIn({required this.toggleView});
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  String email = "";
  String password = "";
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond de la page avec une couleur OLEA claire (Beige)
      backgroundColor: const Color(0xFFE3D9C0), // OLEA Light Beige
      appBar: AppBar(
        title: const Text(
          "Connexion",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white), // Texte blanc pour contraste
        ),
        // Couleur de l'AppBar principale OLEA (Rouge-Orange)
        backgroundColor: const Color(0xFFB7482B), // OLEA Primary Reddish-Orange
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo OLEA
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'OLEA | ONE',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            // Couleur du logo OLEA (Chocolat foncé)
                            color: const Color(0xFF432918), // OLEA Secondary Dark Brown
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue sur votre plateforme',
                          style: TextStyle(
                            fontSize: 16,
                            // Couleur du texte secondaire (Gris foncé)
                            color: const Color(0xFF666666), // OLEA Primary Dark Gray
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Formulaire dans un conteneur stylisé
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white, // Fond du formulaire reste blanc pour la clarté
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              // Couleur du titre du formulaire (Chocolat foncé)
                              color: const Color(0xFF432918), // OLEA Secondary Dark Brown
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Champ Email
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Entrez votre email',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                // Couleur de l'icône (Rouge-Orange)
                                color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(
                                  color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50], // Garde un gris très clair pour les champs
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() => email = val);
                            },
                            validator: (val) =>
                            val!.isEmpty ? 'Entrez un email' : null,
                          ),

                          const SizedBox(height: 20),
                          // Champ Mot de passe
                          TextFormField(
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: 'Entrez votre mot de passe',
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                // Couleur de l'icône (Rouge-Orange)
                                color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  // Couleur de l'icône (Gris foncé)
                                  color: const Color(0xFF666666), // OLEA Primary Dark Gray
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(
                                  color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() => password = val);
                            },
                            validator: (val) => val!.length < 6
                                ? 'Entrez un mot de passe de plus de 6 caractères'
                                : null,
                          ),

                          const SizedBox(height: 24),

                          // Message d'erreur
                          if (error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50], // Couleur de fond d'erreur reste rouge clair
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red[200]!), // Couleur de bordure d'erreur reste rouge clair
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: TextStyle(
                                        color: Colors.red[700], // Texte d'erreur reste rouge
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Bouton de connexion
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                    error = '';
                                  });

                                  try {
                                    final MyUser? user =
                                    await _auth.signInWithEmailAndPassword(email, password);
                                    if (user?.emailVerified == false) {
                                      // vraiment pas d’utilisateur
                                      setState(() {
                                        error = 'Email non Verifié.';
                                        _isLoading = false;
                                      });
                                      return;
                                    }

                                    setState(() => _isLoading = false);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const wrapper()),
                                    );

                                  } catch (e) {
                                    setState(() {
                                      error = 'Une erreur est survenue. Veuillez réessayer.';
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },

                              style: ElevatedButton.styleFrom(
                                // Couleur du bouton (Rouge-Orange)
                                backgroundColor: const Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 3,
                                // Ombre du bouton (Rouge-Orange avec opacité)
                                shadowColor: const Color(0xFFB7482B).withOpacity(0.4), // OLEA Primary Reddish-Orange
                              ),
                              child: _isLoading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SpinKitFadingCircle(
                                    // Couleur du spinner (Orange principal)
                                    color: const Color(0xFFF8AF3C), // OLEA Primary Orange
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Connexion...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: Color(0xFFB7482B)), // Couleur OLEA
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pas encore de compte ?',
                          style: TextStyle(
                            // Couleur du texte (Gris foncé)
                            color: const Color(0xFF666666), // OLEA Primary Dark Gray
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => widget.toggleView(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              // Bordure du bouton (Rouge-Orange)
                              border: Border.all(color: const Color(0xFFB7482B)), // OLEA Primary Reddish-Orange
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Text(
                              'Créer un compte',
                              style: TextStyle(
                                // Couleur du texte (Rouge-Orange)
                                color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
