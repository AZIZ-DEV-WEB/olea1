import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/admin/AdminOrganismesPage.dart';
import 'package:firstproject/pages/admin/Courses/DashboardCourses.dart';
import 'package:firstproject/pages/admin/admin_users_page.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth.dart';
import '../../widgets/custom_app_bar.dart'; // Assurez-vous que CustomAppBar est bien personnalisé avec OLEA
import 'AdminDepartmentsPage.dart';
import 'AdminProfilePage.dart'; // Import pour la page de profil admin
import 'Courses/CoursesList.dart';
import 'DadhboardEntités.dart';
import 'DashboardFormations.dart';
import 'DemandesFormation/AdminPendingRequests.dart';
import 'AdminReunionsPage.dart';
import 'AdminStatsPage.dart';
import 'DemandesFormation/DemandesFormations.dart';
import 'formation/FormationsTerminés.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  String? _username;
  final AuthService _auth = AuthService();
  MyUser? _currentUser;

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

  final Color oleaLightBeige = const Color(0xFFE3D9C0); // OLEA Light Beige
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B); // OLEA Primary Reddish-Orange

  @override
  void initState() {
    super.initState();
    loadUsername();
    _loadUser();

  }
  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUserData();
    setState(() {
      _currentUser = user;
    });
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

    int colorIndex = 0; // Pour parcourir les couleurs OLEA pour les cartes

    return Scaffold(
      // Fond de la page avec une couleur OLEA claire
      backgroundColor: oleaLightBeige, // OLEA Light Beige
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [


            _buildDashboardCard(
              context,
              Icons.dashboard, // ou Icons.school_outlined
              'Formations',
              oleaCardColors[colorIndex++ % oleaCardColors.length],
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardFormations()),
                );
                if (mounted) setState(() {});
              },
            ),



            //if (_currentUser?.role == 'superadmin')
              _buildDashboardCard(
                context,
                Icons.assignment,
                'Demandes de Formations',
                oleaCardColors[colorIndex++ % oleaCardColors.length],
                cardWidth,
                    () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Demandesformations()),
                  );
                  if (mounted) setState(() {});
                },
              ),

            _buildDashboardCard(
              context,
              Icons.assignment,
              'Gestion des Entités',
              oleaCardColors[colorIndex++ % oleaCardColors.length],
              cardWidth,
                  () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardEntites()),
                );
                if (mounted) setState(() {});
              },
            ),

            _buildDashboardCard(
              context,
              Icons.insights,
              'Statistiques',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle couleur
              cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminStatsPage()),
              );
              if (mounted) setState(() {});
            },),

            _buildDashboardCard(
              context,
              Icons.insights,
              'Cours',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle couleur
              cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardCourses()),
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
      Color color, // Cette couleur viendra maintenant de la palette OLEA
      double width, [
        VoidCallback? onTap,
      ]) {
    return SizedBox(
      width: width,
      height: 130,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.95), // Utilise la couleur OLEA directement
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 34, color: Colors.white), // Icônes restent blanches pour contraste
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white, // Texte reste blanc pour contraste
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
