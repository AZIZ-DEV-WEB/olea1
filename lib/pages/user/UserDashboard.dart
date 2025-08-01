import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/admin/AdminOrganismesPage.dart';
import 'package:firstproject/pages/admin/admin_users_page.dart';
import 'package:firstproject/pages/user/userProfile.dart';
import 'package:flutter/material.dart';
import '../../services/auth.dart';
import '../../widgets/custom_app_bar.dart';
import 'DemandesFormations/DemandesDashboard.dart';
import 'DemandesFormations/DeposerDemande.dart';
import 'DemandesFormations/DemandesHistoriques.dart';
import 'FormationsdDisponibles.dart';
import 'package:firstproject/pages/user/HistoriqueFormations.dart';
import 'package:firstproject/pages/user/UserCourses.dart';

import 'ProchainesFormations.dart';


class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard> {
  String? _username;

  // Define OLEA colors
  final List<Color> oleaCardColors = [
    const Color(0xFFB7482B), // Primary Reddish-Orange
    const Color(0xFFF8AF3C), // Primary Orange
    const Color(0xFF936037), // Secondary Brown
    const Color(0xFF5BBBA0), // Complementary Turquoise
    const Color(0xFF666666), // Primary Dark Gray
    const Color(0xFF432918), // Secondary Dark Brown
    const Color(0xFFC99FB5), // Complementary Pink
  ];

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

    int colorIndex = 0; // To cycle through the OLEA colors for the cards

    return Scaffold(

      // Set the background color of the entire page to a light OLEA color
      backgroundColor: const Color(0xFFF0F0F0), // A very light gray, or use 0xFFCBBBA0 for a light beige

      body:
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildDashboardCard(
              context,
              Icons.people,
              'Mes prochaines formations',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  UserProchainesFormationsPage()),
                );
                if (mounted) setState(() {});
              },
            ),
            _buildDashboardCard(
              context,
              Icons.apartment,
              'Formations disponibles',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserFormationsDisponiblesPage()),
                );
                if (mounted) setState(() {});
              },
            ),
            _buildDashboardCard(
              context,
              Icons.domain,
              'Historique des formations',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserHistoriquesFormationsPage()),
                );
                if (mounted) setState(() {});
              },
            ),
            _buildDashboardCard(
              context,
              Icons.bar_chart,
              'Mes Cours',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MesCoursPage()),
                );
                if (mounted) setState(() {});
              },
            ),


            _buildDashboardCard(
              context,
              Icons.bar_chart,
              'Demandes de Formations',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
              cardWidth,
                  () async {

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  DemandesDashboard ()),
                );

                if (mounted) setState(() {});
              },
            ),
            // Add other cards here, cycling through colors


            // Example for admin-specific cards if needed, using remaining colors
            if (_username != null && _username == 'admin') // Example check for admin role
              _buildDashboardCard(
                context,
                Icons.supervised_user_circle,
                'Gérer les Utilisateurs',
                oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
                cardWidth,
                    () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminUsersPage()),
                  );
                  if (mounted) setState(() {});
                },
              ),
            if (_username != null && _username == 'admin') // Example check for admin role
              _buildDashboardCard(
                context,
                Icons.business,
                'Gérer les Organismes',
                oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle color
                cardWidth,
                    () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminOrganismesPage()),
                  );
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color, // This color will now come from the OLEA palette
      double width, [
        VoidCallback? onTap,
      ]) {
    return SizedBox(
      width: width,
      height: 130,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.95), // Use the OLEA color directly
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: Colors.white), // Icons remain white for contrast
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white, // Text remains white for contrast
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
