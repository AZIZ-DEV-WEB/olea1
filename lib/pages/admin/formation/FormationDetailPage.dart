import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/olea_colors.dart';
import 'EditFormationPage.dart';
import 'package:firstproject/utils/olea_colors.dart';
 class AdminFormationDetailPage extends StatelessWidget {
  final Map<String, dynamic> formationData;

  const AdminFormationDetailPage({super.key, required this.formationData});

  @override
  Widget build(BuildContext context) {
    final calendrier = formationData['calendrier'] as List<dynamic>? ?? [];
    final List<dynamic> participants = formationData['participants'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formationData['titre'] ?? 'Détails',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: OleaColors.oleaPrimaryDarkGray,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Color(0xFFB7482B), // Couleur rouge foncé OLEA
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditFormationPage(
                    formationId: formationData['id'], // assure-toi que l'ID est inclus
                    initialData: formationData,
                    initialSeances: List<Map<String, dynamic>>.from(
                      formationData['calendrier'] ?? [],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: OleaColors.oleaLightBeige.withOpacity(0.2),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(),
              const SizedBox(height: 20),
              _buildSeancesSection(calendrier),
              const SizedBox(height: 20),
              buildParticipantsCard(participants),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final dateDebut = formationData['dateDebut'] != null
        ? (formationData['dateDebut'] as Timestamp).toDate()
        : null;

    final dateFin = formationData['dateFin'] != null
        ? (formationData['dateFin'] as Timestamp).toDate()
        : null;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: OleaColors.oleaLightBeige,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formationData['titre'] ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OleaColors.oleaPrimaryDarkGray,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formationData['description'] ?? '',
              style: TextStyle(fontSize: 16, color: OleaColors.oleaSecondaryDarkBrown),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Statut', formationData['statut']),
            _buildInfoRow('Organisme', formationData['organismenom']),
            _buildInfoRow('Modalité', formationData['modalite']),

            const SizedBox(height: 6),
            if (dateDebut != null && dateFin != null)
              Text(
                '🗓️ Du ${DateFormat('dd/MM/yyyy').format(dateDebut)} au ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                style: const TextStyle(color: Colors.black87),
              ),



          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        '$label : ${value ?? 'N/A'}',
        style: TextStyle(color: OleaColors.oleaPrimaryDarkGray),
      ),
    );
  }

  Widget _buildSeancesSection(List<dynamic> calendrier) {
    if (calendrier.isEmpty) {
      return const Text("Aucune séance programmée.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🗓️ Séances",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: OleaColors.oleaPrimaryReddishOrange,
          ),
        ),
        const SizedBox(height: 8),
        ...calendrier.map((seance) {
          final date = (seance['date'] as Timestamp).toDate();
          final debut = seance['heureDebut'];
          final fin = seance['heureFin'];
          final titre = seance['titre'];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: OleaColors.oleaLightBeige.withOpacity(0.8),
            child: ListTile(
              leading: Icon(Icons.event_note, color: OleaColors.oleaPrimaryOrange),
              title: Text(
                titre,
                style: TextStyle(color: OleaColors.oleaSecondaryDarkBrown),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(date)} | $debut - $fin',
                style: TextStyle(color: OleaColors.oleaPrimaryDarkGray),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget buildParticipantsCard(List<dynamic> participants) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: OleaColors.oleaLightBeige,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: OleaColors.oleaPrimaryReddishOrange,
              ),
            ),
            const SizedBox(height: 12),
            ...participants.map((participant) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person, color: OleaColors.oleaPrimaryDarkGray, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant['username'] ?? 'Nom inconnu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OleaColors.oleaSecondaryDarkBrown,
                            ),
                          ),
                          Text(
                            'Département : ${participant['department'] ?? '---'}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
