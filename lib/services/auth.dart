import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/models/user.dart';

import '../main.dart';

final currentUser = FirebaseAuth.instance.currentUser;
final uid = currentUser?.uid;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Transformer Firebase User en MyUser
  MyUser _userFromFirebaseUser(User user, Map<String, dynamic>? userData) {
    return MyUser(
      uid: user.uid,
      username: userData?['username'] ?? '',
      email: user.email ?? '',
      role: userData?['role'] ?? 'user',
      department: userData?['department'] ?? '',
      poste: userData?['poste'] ?? '',
      joinDate: (userData?['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: '',
    );
  }

  // Inscription avec email, password, department
  Future<MyUser?> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
    required String department,
    required String role ,
    required String poste,

  })

  async {
    try {
      // 1. Créer l’utilisateur Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) return null;

      // 2. Créer le document Firestore lié à l’utilisateur
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'role': role,
        'department': department,
        'createdAt': FieldValue.serverTimestamp(),
        'poste': poste,
        'joinDate': FieldValue.serverTimestamp(),
      });

      // 3. Récupérer les données utilisateur
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(user.uid).get();

      return _userFromFirebaseUser(user, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Erreur inscription : $e');
      return null;
    }
  }


  Future<MyUser?> getCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    return _userFromFirebaseUser(user, data);
  }



  Future<void> createUserAsAdmin({
    required String username,
    required String email,
    required String password,
    required String department,
    required String poste,
  }) async {
    try {
      // Sauvegarder l’admin actuellement connecté
      final User? adminUser = _auth.currentUser;
      final String? adminEmail = adminUser?.email;
      if (adminUser == null || adminEmail == null) throw Exception('Admin non connecté');

      // Demander le mot de passe admin
      final String? adminPassword = await _getAdminPassword(); // fonction à créer ci-dessous
      if (adminPassword == null || adminPassword.isEmpty) return;

      // Créer le nouvel utilisateur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = result.user;
      if (newUser == null) throw Exception('Création utilisateur échouée');

      // Ajouter les infos Firestore
      await _firestore.collection('users').doc(newUser.uid).set({
        'username': username,
        'email': email,
        'department': department,
        'poste': poste,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'joinDate': FieldValue.serverTimestamp(),
      });

      // Se reconnecter avec l’admin
      await _auth.signOut();
      await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
    } catch (e) {
      print('Erreur createUserAsAdmin: $e');
      rethrow;
    }
  }


  Future<String?> _getAdminPassword() async {
    final TextEditingController _ctrl = TextEditingController();
    return await showDialog<String>(
      context: navigatorKey.currentContext!, // Assure-toi d’avoir un navigatorKey global
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe admin'),
        content: TextField(
          controller: _ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mot de passe'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Confirmer')),
        ],
      ),
    );
  }


  // Connexion avec email + mot de passe
  Future<MyUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Document utilisateur non trouvé
        return null;
      }

      return _userFromFirebaseUser(user, doc.data() as Map<String, dynamic>?);
    } catch (e) {
      print('Erreur connexion : $e');
      return null;
    }
  }
  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur de déconnexion : $e');
    }
  }

  // Stream pour détecter l'état de connexion de l'utilisateur
  Stream<MyUser?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;

      DocumentSnapshot doc =
      await _firestore.collection('users').doc(user.uid).get();

      return _userFromFirebaseUser(user, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> deleteUser(MyUser user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Assure-toi que `user.id` est bien le doc ID
          .delete();
    } catch (e) {
      debugPrint('Erreur suppression utilisateur : $e');
    }
  }


  Future<void> updateUser(MyUser updatedUser) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.uid)
          .update({
        'username': updatedUser.username,
        'email': updatedUser.email,
        'department': updatedUser.department,
        'poste': updatedUser.poste,
        'role': updatedUser.role,



      });
    } catch (e) {
      debugPrint('Erreur mise à jour utilisateur : $e');
    }
  }


}
