import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Transformer Firebase User en MyUser
  MyUser _userFromFirebaseUser(User user, Map<String, dynamic>? userData) {
    return MyUser(
      uid: user.uid,
      email: user.email ?? '',
      role: userData?['role'] ?? 'user',
      department: userData?['department'] ?? '',
    );
  }

  // Inscription avec email, password, department
  Future<MyUser?> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
    String department = '',
    String role = ''
  }) async {
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
}
