import 'package:flutter/material.dart';

import '../services/auth.dart';

class acceuil extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true, // ✅ ceci centre le texte
        title: Text("HomePage"),
        elevation: 0.0,
        backgroundColor: Colors.orange,
        actions: <Widget>[
          TextButton.icon(
              icon: Icon(Icons.person),
              label: Text("Déconnexion"),
              onPressed: () async {
                await _auth.signOut();
              },
          )
        ],
      ),
      body: Center( // ✅ Ce widget centre la Column dans toute la page
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ pour que la Column prenne juste la hauteur nécessaire
          children: [
            Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text("Bienvenue sur notre application OLEA 2025 !",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),

    );
  }
}
