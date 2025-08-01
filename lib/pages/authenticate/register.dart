import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/auth.dart';
import '../../widgets/department_dropdown.dart';
import 'package:firstproject/pages/authenticate/verificationEmail.dart';


class register extends StatefulWidget {
  final Function toggleView;
  register({required this.toggleView});

  @override
  State<register> createState() => _registerState();
}

class _registerState extends State<register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String username="";
  String email = "";
  String? department; // initialisé à null
  String poste=""; // variable sélectionnée
  String password = "";
  final TextEditingController adminCodeController = TextEditingController();
  String selectedRole = 'user'; // valeur par défaut
  final String adminSecretCode = 'OLEA2024'; // code à valider pour admin
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
          "Inscription",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white, // Texte blanc pour contraste
          ),
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
                    margin: const EdgeInsets.only(bottom: 20),
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
                          'Rejoignez notre communauté',
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
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              // Couleur du titre du formulaire (Chocolat foncé)
                              color: const Color(0xFF432918), // OLEA Secondary Dark Brown
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Champ Nom d'utilisateur
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              hintText: 'Entrez votre nom d\'utilisateur',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                // Couleur de l'icône (Rouge-Orange)
                                color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(color: Color(0xFFB7482B), width: 2), // OLEA Primary Reddish-Orange
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              // Couleur de remplissage des champs (gris très clair)
                              fillColor: Colors.grey[50], // Garde un gris très clair pour les champs
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            onChanged: (val) {
                              setState(() => username = val);
                            },
                            validator: (val) => val!.isEmpty ? 'Entrez un nom d\'utilisateur' : null,
                          ),

                          const SizedBox(height: 20),

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
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(color: Color(0xFFB7482B), width: 2), // OLEA Primary Reddish-Orange
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            onChanged: (val) {
                              setState(() => email = val);
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Entrez un email';
                              } else if (!val.endsWith('@gmail.com')) {
                                return 'Utilisez un email @gmail.com';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Dropdown pour le département
                          DepartmentDropdown(
                            selected: department,
                            onChanged: (value) {
                              setState(() {
                                department = value;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Champ Poste de travail
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Poste de travail',
                              hintText: 'Entrez votre poste',
                              prefixIcon: const Icon(
                                Icons.work_outline,
                                // Couleur de l'icône (Rouge-Orange)
                                color: Color(0xFFB7482B), // OLEA Primary Reddish-Orange
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(color: Color(0xFFB7482B), width: 2), // OLEA Primary Reddish-Orange
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            onChanged: (val) {
                              setState(() => poste = val);
                            },
                            validator: (val) => val == null || val.isEmpty ? 'Entrez votre poste' : null,
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
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                // Couleur du focus (Rouge-Orange)
                                borderSide: const BorderSide(color: Color(0xFFB7482B), width: 2), // OLEA Primary Reddish-Orange
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20), // Icône d'erreur reste rouge
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: TextStyle(color: Colors.red[700], fontSize: 14), // Texte d'erreur reste rouge
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Bouton d'inscription
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child:
                            ElevatedButton(
                              onPressed: _isLoading ? null : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                    error = '';
                                  });

                                  await Future.delayed(const Duration(seconds: 1)); // optionnel pour l'effet de chargement

                                  if (department != null && selectedRole != null) {
                                    bool success = await _auth.registerWithEmailAndPassword(
                                      username: username,
                                      email: email,
                                      password: password,
                                      department: department!,
                                      poste: poste,
                                      role: 'user',
                                      emailVerified: false,

                                    );

                                    if (success == true) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EmailVerificationPage(
                                            username: username,
                                            email: email,
                                            department: department!,
                                            poste: poste,
                                          ),
                                        ),
                                      );

                                    }
                                    else {
                                      setState(() {
                                        error = "Échec de l'inscription. Vérifiez l’e-mail et réessayez.";
                                        _isLoading = false;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      error = 'Veuillez remplir tous les champs requis.';
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
                                    'Inscription...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : const Text(
                                "S'inscrire",
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

                  // Ajustement des SizedBox pour remonter le bouton "Se connecter"
                  const SizedBox(height: 10), // Réduit l'espace après le formulaire principal

                  // Lien vers connexion
                  Text(
                    'Vous avez déjà un compte ?',
                    style: TextStyle(
                      // Couleur du texte (Gris foncé)
                      color: const Color(0xFF666666), // OLEA Primary Dark Gray
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4), // Réduit l'espace entre le texte et le bouton
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
                        'Se connecter',
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
          ),
        ),
      ),
    );
  }
}
