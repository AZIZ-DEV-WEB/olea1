import 'package:flutter/material.dart';

import 'formation/FormationsEnCoursPage.dart';
import 'formation/FormationsPlanifieesPage.dart';
import 'formation/FormationsTerminés.dart';
//import 'FormationsEnCoursPage.dart';   // à créer si besoin
//import 'FormationsPlanifieesPage.dart'; // à créer si besoin

class DashboardFormations extends StatelessWidget {
  const DashboardFormations({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 2 : 3;
    final double cardWidth =
        (screenWidth - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;

    final List<Color> cardColors = [
      const Color(0xFFB7482B), // rouge foncé
      const Color(0xFFF8AF3C), // orange
      const Color(0xFF666666), // gris foncé
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations'),
        backgroundColor: const Color(0xFF666666), // Gris foncé
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [

            _buildDashboardCard(
              context,
              Icons.schedule,
              'Formations Planifiées',
              cardColors[2],
              cardWidth,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormationsPlanifieesPage(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.check_circle_outline,
              'Formations Terminées',
              cardColors[0],
              cardWidth,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormationsTermineesPage(),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              Icons.play_circle_fill,
              'Formations en Cours',
              cardColors[1],
              cardWidth,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormationsEnCoursPage(),
                  ),
                );
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
