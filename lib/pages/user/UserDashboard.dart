import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/admin/AdminOrganismesPage.dart';
import 'package:firstproject/pages/admin/admin_users_page.dart';
import 'package:firstproject/pages/user/userProfile.dart';
import 'package:flutter/material.dart';
import '../../services/auth.dart';
import '../../widgets/custom_app_bar.dart';
import 'FormationsdDisponibles.dart';
import 'package:firstproject/pages/user/HistoriqueFormations.dart';
import 'package:firstproject/pages/user/UserMessagerie.dart';
import 'package:firstproject/pages/user/UserReunions.dart';
import 'package:firstproject/pages/user/UserStatistiques.dart';

import 'ProchainesFormations.dart';


class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard> {
  String? _username;

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

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
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 2 : 3;
    final double cardWidth =
        (screenWidth - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Admin'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      
      body: 
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildDashboardCard(
              context, Icons.people, 'Mes prochaines formations', Colors.green, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  UserProchainesFormationsPage()),
              );
              if (mounted) setState(() {});
            },),
              _buildDashboardCard(
              context, Icons.apartment, 'Formations disponibles', Colors.teal, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserFormationsDisponiblesPage()),
              );
              if (mounted) setState(() {});
            },),
            _buildDashboardCard(
              context, Icons.domain, 'Historique des formations', Colors.purple, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserHistoriquesFormationsPage()),
              );
              if (mounted) setState(() {});
            },),

            _buildDashboardCard(
              context, Icons.bar_chart, 'Statistiques', Colors.orange, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserstatistiquesPage()),
              );
              if (mounted) setState(() {});
            },),





            _buildDashboardCard(
              context, Icons.message, 'Messagerie', Colors.red, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserMessageriePage()),
              );
              if (mounted) setState(() {});
            },),

            _buildDashboardCard(
              context, Icons.meeting_room, 'Réunions', Colors.pink, cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserReunionsPage()),
              );
              if (mounted) setState(() {});
            },),

          ],
        ),
      ),

    );

  }

  Widget _buildDashboardCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
      double width, [
        VoidCallback? onTap,
      ]) {
    return SizedBox(
      width: width,
      height: 130,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.95),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
