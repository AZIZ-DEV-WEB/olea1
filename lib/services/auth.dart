import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/models/user.dart';
import 'package:firstproject/services/auth.dart';
import 'package:firstproject/pages/device_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb; // Alias Supabase for clarity


import '../main.dart'; // Ensure navigatorKey is accessible from here

final currentUser = FirebaseAuth.instance.currentUser;
final uid = currentUser?.uid;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final sb.SupabaseClient _supabase = sb.Supabase.instance.client; // Supabase Client instance

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
      photoUrl: '', // This might need to be fetched from Firebase User or Firestore
      emailVerified: userData?['emailVerified'] ?? false,
    );
  }

  // Inscription avec email, password, department (MODIFIED for Supabase)
  Future<bool> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
    required String department,
    required String role,
    required String poste,
    required bool emailVerified, // This 'emailVerified' argument might be redundant as it's set to false initially
  }) async {
    try {
      if (!email.endsWith('@gmail.com')) {
        throw FirebaseAuthException(
          code: 'invalid-domain',
          message: 'L\'email doit se terminer par @gmail.com',
        );
      }

      // 1. Créer l'utilisateur dans Firebase Auth
      UserCredential firebaseResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = firebaseResult.user;

      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'firebase-user-creation-failed',
          message: 'Impossible de créer l\'utilisateur dans Firebase',
        );
      }

      // 2. Créer l'utilisateur dans Supabase Auth
      // This will automatically log them in to Supabase and set a session.
      final sb.AuthResponse supabaseAuthResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (supabaseAuthResponse.user == null) {
        // If Supabase signup fails, consider deleting the Firebase user to prevent inconsistencies
        await firebaseUser.delete(); // Delete Firebase user
        throw sb.AuthException('Impossible de créer l\'utilisateur dans Supabase.');
      }

      // 3. Envoyer l'email de vérification Firebase
      await firebaseUser.sendEmailVerification();

      // 4. Enregistrer les données utilisateur dans Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'username': username,
        'email': email,
        'role': role,
        'department': department,
        'poste': poste,
        'createdAt': FieldValue.serverTimestamp(),
        'joinDate': FieldValue.serverTimestamp(),
        'emailVerified': false, // Initialement false, vérifié après validation email
      });

      print('[AUTH SERVICE] ✅ Utilisateur créé dans Firebase et Supabase, email de vérification envoyé.');
      return true;
    } on FirebaseAuthException catch (e) {
      print('[AUTH SERVICE] FirebaseAuthException lors de l\'inscription: ${e.code} - ${e.message}');
      return false;
    } on sb.AuthException catch (e) {
      print('[AUTH SERVICE] Supabase AuthException lors de l\'inscription: ${e.message}');
      return false;
    } catch (e) {
      print('[AUTH SERVICE] Erreur inattendue lors de l\'inscription: $e');
      return false;
    }
  }

  // --- MODIFIED getCurrentUserData FUNCTION ---
  Future<MyUser?> getCurrentUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      // If no Firebase user, ensure Supabase session is also cleared
      if (_supabase.auth.currentUser != null) {
        print('[AUTH SERVICE] 🔄 Logging out Supabase session as no Firebase user is found.');
        await _supabase.auth.signOut();
      }
      return null;
    }

    // --- NEW: Attempt to establish Supabase session if not active ---
    if (_supabase.auth.currentUser == null) {
      print('[AUTH SERVICE] ⚠️ Firebase user found, but no active Supabase session. Attempting to establish...');
      try {
        // Get the Firebase ID Token
        final String? firebaseIdToken = await firebaseUser.getIdToken(true); // true to force refresh
        if (firebaseIdToken != null) {
          // IMPORTANT: This requires a Supabase Custom JWT Provider setup
          // where Supabase trusts Firebase's ID Tokens.
          // If you haven't set this up in Supabase, this call will likely fail.
          // Alternatively, if you're sure you want to use the email/password
          // again (e.g., if you store it or it's implicitly known), you could
          // try signInWithPassword here, but that's less ideal for silent re-auth.
          final sb.AuthResponse response = await _supabase.auth.signInWithIdToken(
            provider: sb.OAuthProvider.google, // This is a placeholder; you'd need a custom JWT provider matching Firebase.
            idToken: firebaseIdToken,
          );

          if (response.user != null) {
            print('[AUTH SERVICE] ✅ Supabase session re-established using Firebase ID Token.');
          } else {
            print('[AUTH SERVICE] ❌ Failed to re-establish Supabase session using Firebase ID Token: ${response.session?.isExpired == true ? "Token expired" : "Unknown error"}.');

          }
        } else {
          print('[AUTH SERVICE] ❌ Firebase ID Token is null, cannot re-establish Supabase session.');
        }
      } on sb.AuthException catch (e) {
        print('[AUTH SERVICE] ❌ Supabase AuthException during re-establishment: ${e.message}');
      } catch (e) {
        print('[AUTH SERVICE] ❌ General error during Supabase session re-establishment: $e');
      }
    }
    // --- END NEW ---


    final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      print('[AUTH SERVICE] ❌ Firestore profile does not exist for Firebase UID: ${firebaseUser.uid}. Logging out all sessions.');
      await _auth.signOut();
      await _supabase.auth.signOut();
      return null;
    }

    return _userFromFirebaseUser(firebaseUser, data);
  }
  Future<void> createUserAsSuperAdmin({
    required String username,
    required String email,
    required String password,
    required String department,
    required String poste,
    required String role,
  }) async {
    try {
      final User? superadminUser = _auth.currentUser;
      if (superadminUser == null) throw Exception('Admin non connecté');

      final String? superadminPassword = await _getSuperAdminPassword();
      if (superadminPassword == null || superadminPassword.isEmpty) return;

      // 1. Créer l'utilisateur dans Firebase Auth
      UserCredential firebaseResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUser = firebaseResult.user;
      if (newUser == null) throw Exception('Création utilisateur Firebase échouée');

      // 2. Créer l'utilisateur dans Supabase Auth
      final sb.AuthResponse supabaseAuthResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (supabaseAuthResponse.user == null) {
        await newUser.delete(); // Rollback Firebase user if Supabase fails
        throw sb.AuthException('Création utilisateur Supabase échouée');
      }

      // 3. Ajouter les infos Firestore
      await _firestore.collection('users').doc(newUser.uid).set({
        'username': username,
        'email': email,
        'department': department,
        'poste': poste,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'joinDate': FieldValue.serverTimestamp(),
        'emailVerified': false, // Superadmins usually don't need email verification via flow
      });

      print('[AUTH SERVICE] ✅ SuperAdmin créé dans Firebase et Supabase');

    } on FirebaseAuthException catch (e) {
      print('[AUTH SERVICE] FirebaseAuthException lors de la création de SuperAdmin: $e');
      rethrow;
    } on sb.AuthException catch (e) {
      print('[AUTH SERVICE] Supabase AuthException lors de la création de SuperAdmin: $e');
      rethrow;
    } catch (e) {
      print('[AUTH SERVICE] Erreur createUserAsSuperAdmin: $e');
      rethrow;
    }
  }

  Future<String?> _getSuperAdminPassword() async {
    final TextEditingController _ctrl = TextEditingController();
    return await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe SuperAdmin'),
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

// --- NOUVELLE FONCTION POUR GÉRER LE TOKEN FCM ---
  Future<void> _saveFcmTokenToFirestore(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token == null) return;

    final ref = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final List<dynamic> existing = snap.data()?['fcmTokens'] ?? [];

      // Ajoute le token s’il n’existe pas déjà
      if (!existing.contains(token)) {
        existing.add(token);
        tx.set(ref, {'fcmTokens': existing}, SetOptions(merge: true));
      }
    });

    // Met à jour automatiquement en cas de refresh
    messaging.onTokenRefresh.listen((newToken) async {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final List<dynamic> existing = snap.data()?['fcmTokens'] ?? [];
        if (!existing.contains(newToken)) {
          existing.add(newToken);
          tx.set(ref, {'fcmTokens': existing}, SetOptions(merge: true));
        }
      });
    });
  }

  // Connexion avec email + mot de passe (MODIFIED for Supabase)
  /// Retourne `MyUser` UNIQUEMENT si :
  /// 1) authentification Firebase réussie
  /// 2) authentification Supabase réussie
  /// 3) e‑mail réellement vérifié (user.emailVerified == true)
  /// 4) document Firestore présent
  Future<MyUser?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async
  {
    try {
      // 1. Authenticate with Firebase
      UserCredential firebaseResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = firebaseResult.user;
      if (firebaseUser == null) {
        print('[AUTH SERVICE] ❌ Firebase user is null after authentication.');
        return null;
      }
      print('[AUTH SERVICE] ✅ Firebase user authenticated: ${firebaseUser.uid}');

      // 2. Authenticate with Supabase (with fallback for existing Firebase users)
      sb.AuthResponse supabaseAuthResponse;
      try {
        // Attempt to sign in with Supabase
        supabaseAuthResponse = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on sb.AuthException catch (e) {
        // If the error indicates user not found or invalid credentials in Supabase,
        // attempt to sign them up.
        // Common messages: 'Invalid login credentials', 'User not found'.
        if (e.message.contains('Invalid login credentials') || e.message.contains('User not found')) {
          print('[AUTH SERVICE] Supabase user not found, attempting automatic sign-up...');
          try {
            supabaseAuthResponse = await _supabase.auth.signUp(
              email: email,
              password: password,
            );
            print('[AUTH SERVICE] ✅ Supabase user signed up successfully during login.');
          } on sb.AuthException catch (signUpError) {
            print('[AUTH SERVICE] ❌ Failed to sign up Supabase user for existing account: ${signUpError.message}');
            await _auth.signOut(); // Log out from Firebase if Supabase fails
            return null;
          }
        } else {
          // Other unexpected Supabase authentication error
          print('[AUTH SERVICE] ❌ Unexpected Supabase authentication error: ${e.message}');
          await _auth.signOut(); // Log out from Firebase
          return null;
        }
      }

      if (supabaseAuthResponse.user == null) {
        print('[AUTH SERVICE] ❌ Supabase user is null after authentication/sign-up attempt.');
        await _auth.signOut(); // Log out from Firebase if Supabase fails
        return null;
      }
      print('[AUTH SERVICE] ✅ Supabase user authenticated: ${supabaseAuthResponse.user!.id}');


      // 3. Manage FCM tokens and Device IDs (Firestore)
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final deviceId = await DeviceHelper.getDeviceId();

      print('[DEVICE] fcmToken: $fcmToken');
      print('[DEVICE] deviceId: $deviceId');

      if (fcmToken != null && deviceId.isNotEmpty) {
        final ref = _firestore.collection('users').doc(firebaseUser.uid);
        final doc = await ref.get();

        print('[FIRESTORE] User Firestore document retrieved: ${doc.exists}');

        final data = doc.data() ?? {};
        final List devices = List.from(data['devices'] ?? []);

        print('[FIRESTORE] Current list of devices: $devices');

        final existingIndex = devices.indexWhere((d) => d['deviceId'] == deviceId);
        print('[DEVICE] Index of current device: $existingIndex');

        if (existingIndex != -1) {
          print('[DEVICE] 🔁 Updating existing device.');
          await ref.update({
            'devices.$existingIndex.fcmToken': fcmToken,
            'devices.$existingIndex.isOnline': true,
            'devices.$existingIndex.lastSeen': Timestamp.now(),
          });
        } else {
          print('[DEVICE] ➕ Adding a new device.');
          await ref.set({
            'devices': FieldValue.arrayUnion([
              {
                'deviceId': deviceId,
                'fcmToken': fcmToken,
                'isOnline': true,
                'lastSeen': Timestamp.now(),
              }
            ])
          }, SetOptions(merge: true));
        }
      } else {
        print('[DEVICE] ❌ FCM token or Device ID is missing.');
      }

      // 4. Reload Firebase user and verify email
      await firebaseUser.reload();
      firebaseUser = _auth.currentUser; // Get the reloaded user

      if (firebaseUser == null || !firebaseUser.emailVerified) {
        print('[AUTH SERVICE] ❌ Email NOT verified for ${firebaseUser?.email}');
        await _auth.signOut(); // Log out from Firebase
        await _supabase.auth.signOut(); // Log out from Supabase
        return null;
      }

      // 5. Retrieve Firestore profile document (must exist)
      final doc2 = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc2.exists) {
        print('[AUTH SERVICE] ❌ Firestore profile does not exist for Firebase UID: ${firebaseUser.uid}');
        await _auth.signOut(); // Log out from Firebase
        await _supabase.auth.signOut(); // Log out from Supabase
        return null;
      }

      print('[AUTH SERVICE] ✅ Login successful, valid profile, and active Supabase session.');
      return _userFromFirebaseUser(
        firebaseUser,
        doc2.data() as Map<String, dynamic>,
      );
    } on FirebaseAuthException catch (e) {
      print('[AUTH SERVICE] Firebase login error: ${e.code} - ${e.message}');
      return null;
    } on sb.AuthException catch (e) {
      // This catch block will only execute for Supabase errors NOT caught by the inner try-catch
      print('[AUTH SERVICE] Supabase login error: ${e.message}');
      return null;
    } catch (e) {
      print('[AUTH SERVICE] General login error: $e');
      return null;
    }
  }


  // Déconnexion (MODIFIED for Supabase)
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser; // Firebase user
      final deviceId = await DeviceHelper.getDeviceId();

      if (user != null) {
        final uid = user.uid;
        final ref = _firestore.collection('users').doc(uid);

        final snapshot = await ref.get();
        final data = snapshot.data();

        if (data != null && data['devices'] != null) {
          var rawDevices = data['devices'];
          List devices = [];
          if (rawDevices is List) {
            devices = List.from(rawDevices);
          } else {
            print("⚠️ Le champ devices n'est pas une liste, il sera ignoré.");
          }

          final updatedDevices = devices.map((device) {
            if (device['deviceId'] == deviceId) {
              return {
                ...device,
                'isOnline': false,
                'lastSeen': Timestamp.now(),
              };
            }
            return device;
          }).toList();

          await ref.update({'devices': updatedDevices});
          print('[AUTH SERVICE] 🔁 Appareil $deviceId marqué offline');
        }
      }

      await _auth.signOut(); // Sign out from Firebase
      await _supabase.auth.signOut(); // Sign out from Supabase
      print('✅ Déconnecté avec succès de Firebase et Supabase');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }

  // Stream pour détecter l'état de connexion de l'utilisateur
  // This stream will primarily reflect Firebase Auth state.
  // Supabase auth state is managed implicitly by the login/logout calls.
  Stream<MyUser?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) {
        // If Firebase user logs out, also ensure Supabase session is cleared
        if (_supabase.auth.currentUser != null) {
          await _supabase.auth.signOut();
        }
        return null;
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) {
        // Le document utilisateur n'existe pas, déconnecter de tout
        await _auth.signOut();
        await _supabase.auth.signOut();
        return null;
      }

      final userData = doc.data() as Map<String, dynamic>;
      return _userFromFirebaseUser(user, userData);
    });
  }

  Future<void> deleteUser(MyUser user) async {
    try {
      // 1. Supprimer l'utilisateur de Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 2. Supprimer l'utilisateur de Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == user.uid) {
        await firebaseUser.delete();
      } else {
        // If the current user is not the one being deleted,
        // you might need admin SDK or re-authenticate the current user to delete others.
        print('[AUTH SERVICE] Impossible de supprimer l\'utilisateur Firebase directement. L\'utilisateur connecté n\'est pas celui à supprimer.');
      }

      // 3. Supprimer l'utilisateur de Supabase Auth
      // This often requires admin privileges or the user being currently logged in to Supabase
      // If `user.id` is the Supabase UUID, you might attempt:
      // await _supabase.rpc('delete_user_by_id', params: {'user_id': user.id});
      // or similar if you have a specific admin function.
      // For simplicity, if the user deletes their *own* account:
      if (_supabase.auth.currentUser?.id == user.uid) { // Assuming Firebase UID and Supabase ID are aligned
        await _supabase.auth.signOut(); // Sign out the current Supabase user
        // Supabase user deletion itself is often done via admin API or self-deletion by the user.
        // A simple `_supabase.auth.currentUser!.delete()` doesn't exist client-side.
      } else {
        print('[AUTH SERVICE] Suppression de l\'utilisateur Supabase via l\'application client non implémentée pour les autres utilisateurs.');
      }

      print('✅ Utilisateur ${user.uid} supprimé avec succès de Firestore, Firebase et Supabase (si connecté)');
    } catch (e) {
      debugPrint('[AUTH SERVICE] Erreur suppression utilisateur : $e');
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

      // If email changes, you might need to update in Firebase and Supabase too.
      // This gets complex, as changing email in Auth services often requires re-authentication.
      // For now, assuming email changes are handled separately or by the auth providers.

      print('✅ Utilisateur ${updatedUser.uid} mis à jour dans Firestore');
    } catch (e) {
      debugPrint('[AUTH SERVICE] Erreur mise à jour utilisateur : $e');
    }
  }
}