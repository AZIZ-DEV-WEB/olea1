import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère la largeur de l'écran
    double screenWidth = MediaQuery.of(context).size.width;

    // Détermine le nombre de colonnes en fonction de la largeur
    int crossAxisCount = screenWidth < 600 ? 2 : 3;

    // Calcule la largeur de chaque carte
    double cardWidth = (screenWidth - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildDashboardCard(context, Icons.person, 'Profil', Colors.grey, cardWidth),
            _buildDashboardCard(context, Icons.school, 'Formations', Colors.blue, cardWidth),
            _buildDashboardCard(context, Icons.people, 'Utilisateurs', Colors.green, cardWidth),
            _buildDashboardCard(context, Icons.bar_chart, 'Statistiques', Colors.orange, cardWidth),
            _buildDashboardCard(context, Icons.domain, 'Départements', Colors.purple, cardWidth),
            _buildDashboardCard(context, Icons.apartment, 'Organismes', Colors.teal, cardWidth),
            _buildDashboardCard(context, Icons.message, 'Messagerie', Colors.red, cardWidth),
            _buildDashboardCard(context, Icons.meeting_room, 'Réunions', Colors.pink, cardWidth),


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
      double width,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/${title.toLowerCase()}');
      },
      child: Container(
        width: width,
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
