import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/services/auth.dart';


class MyUser {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;
  final String username;
  final String email;
  final String department;
  final String role;
  final String poste;
  final String photoUrl;
  final DateTime joinDate;




  MyUser({
    required this.username,
    required this.uid,
    required this.email,
    required this.department,
    required this.role,
    required this.poste,
    required this.photoUrl,
    required this.joinDate,

  });


  static Stream<List<MyUser>> streamUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();            // ↓ opérateur ?? '' pour éviter null
      return MyUser(
        uid: doc.id,
        email: data['email'] as String? ?? '',
        username: data['username'] as String? ?? '',
        department: data['department'] as String? ?? '',
        poste: data['poste'] as String? ?? '',
        role: data['role'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? '',
        joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList());
  }




}
