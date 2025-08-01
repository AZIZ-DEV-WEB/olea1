import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/auth.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../user/DemandesFormations/DeposerDemande.dart';
import 'CoursesList.dart';







class DashboardCourses extends StatefulWidget {
  const DashboardCourses({super.key});

  @override
  State<DashboardCourses> createState() => DashboardCoursesState();
}

class DashboardCoursesState extends State<DashboardCourses> {
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
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        backgroundColor: oleaPrimaryReddishOrange,
      ),


      body:
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [


            _buildDashboardCard(
              context,
              Icons.account_tree,
              'Liste des Cours',
              oleaCardColors[colorIndex++ % oleaCardColors.length], // Cycle couleur
              cardWidth, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoursesPage()),
              );
              if (mounted) setState(() {});
            },),

            // Add other cards here, cycling through colors




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
