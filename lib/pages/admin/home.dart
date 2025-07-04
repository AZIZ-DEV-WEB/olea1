import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firstproject/pages/admin/dashboard.dart';
import 'package:firstproject/widgets/modalités.dart';
import 'package:firstproject/pages/admin/formation/addFormation.dart';
import '../../services/auth.dart';
import '../../widgets/custom_app_bar.dart';
import 'formation/FormationsListPage.dart';


class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<Map<String, dynamic>> _calendrier = [];
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

  @override
  void initState() {
    super.initState();
    loadUsername(); // Charge le nom de l'utilisateur dès que la page est ouverte
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        username: _username,
        getAppBarTitle: () {
          switch (_currentIndex) {
            case 0:
              return 'Tableau de Bord Admin';
            case 1:
              return 'Liste des Formations';
            case 2:
              return 'Ajouter une Formation';
            default:
              return 'Admin';
          }
        },        onLogout: () async {
          await _auth.signOut();
          // Ajoute ton AuthService ou FirebaseAuth.instance.signOut()
          //Navigator.pushReplacementNamed(context, '/');
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminDashboard(),
          FormationsListPage(),
          Addformation(),
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Formations'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Ajouter une formation',
          ),
        ],
      ),
    );
  }









}
