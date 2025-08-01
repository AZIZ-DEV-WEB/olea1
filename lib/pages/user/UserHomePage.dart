import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/acceuil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart';

import '../../services/auth.dart';
import '../../widgets/custom_app_bar.dart';
import 'PrgSeances.dart';
import 'UserDashboard.dart';





class Userhomepage extends StatefulWidget {
  const Userhomepage({super.key});

  @override
  State<Userhomepage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<Userhomepage> {
  final AuthService _auth = AuthService();
  String? _username;

  int _currentIndex = 0;
  Future<void> loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        _username = doc['username']; // ou 'nom' selon ton champ Firestore
      });
    }
  }


  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        username: _username,
        getAppBarTitle: () {
          switch (_currentIndex) {
            case 0:
              return 'Dashboard OLEA';
            case 1:
              return 'Liste des Formations';
            default:
              return 'User';
          }
        },        onLogout: () async {
        await _auth.signOut();
        // Ajoute ton AuthService ou FirebaseAuth.instance.signOut()
        //Navigator.pushReplacementNamed(context, '/');
      },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          UserDashboard(),
          PrgSeancesPage(),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Mes Séances'),
        ],
      ),
    );
  }
}
