import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firstproject/utils/olea_colors.dart'; // Ensure this path is correct

class PrgSeancesPage extends StatelessWidget {
  const PrgSeancesPage({super.key});

  DateTime? _parseHeure(String heure) {
    final List<DateFormat> formats = [
      DateFormat('HH:mm'), // Format 24h
      DateFormat('hh:mm a'), // Format 12h avec AM/PM
    ];

    for (final format in formats) {
      try {
        return format.parse(heure);
      } catch (_) {}
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes séances programmées',
          style: TextStyle(color: Colors.white), // Set app bar title color to white
        ),
        backgroundColor: OleaColors.oleaPrimaryReddishOrange, // Use Olea primary color for app bar
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color to white
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('participations')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: 'invited')
            .snapshots(),
        builder: (context, pSnap) {
          if (!pSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final participations = pSnap.data!.docs;
          final formationIds =
          participations.map((doc) => doc['formationId'] as String).toList();

          if (formationIds.isEmpty) {
            return const Center(child: Text('Aucune séance à venir.'));
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('formations')
                .where(FieldPath.documentId, whereIn: formationIds)
                .get(),
            builder: (context, fSnap) {
              if (!fSnap.hasData) return const CircularProgressIndicator();

              final formations = fSnap.data!.docs;
              final Map<String, List<Map<String, dynamic>>> groupedSeances = {};

              for (var doc in formations) {
                final fData = doc.data() as Map<String, dynamic>;
                final titreFormation = fData['titre'] ?? 'Sans titre';
                final calendrier =
                List<Map<String, dynamic>>.from(fData['calendrier'] ?? []);
                bool updated = false;

                for (int i = 0; i < calendrier.length; i++) {
                  final seance = calendrier[i];
                  final Timestamp? ts = seance['date'];
                  final String heureDebut = seance['heureDebut'] ?? '';
                  final String heureFin = seance['heureFin'] ?? '';

                  if (ts == null || heureDebut.isEmpty || heureFin.isEmpty) continue;

                  final DateTime baseDate = ts.toDate();

                  final parsedDebut = _parseHeure(heureDebut);
                  final parsedFin = _parseHeure(heureFin);

                  if (parsedDebut == null || parsedFin == null) continue;

                  final DateTime startTime = DateTime(
                    baseDate.year,
                    baseDate.month,
                    baseDate.day,
                    parsedDebut.hour,
                    parsedDebut.minute,
                  );

                  final DateTime endTime = DateTime(
                    baseDate.year,
                    baseDate.month,
                    baseDate.day,
                    parsedFin.hour,
                    parsedFin.minute,
                  );

                  final now = DateTime.now();
                  String newStatut;

                  if (now.isBefore(startTime)) {
                    newStatut = 'Planifiée';
                  } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
                    newStatut = 'En Cours';
                  } else {
                    newStatut = 'Terminée';
                  }

                  if (seance['statut'] != newStatut) {
                    calendrier[i]['statut'] = newStatut;
                    updated = true;
                  }
                }

                if (updated) {
                  FirebaseFirestore.instance
                      .collection('formations')
                      .doc(doc.id)
                      .update({
                    'calendrier': calendrier,
                  });
                }

                final seances = calendrier.where((s) {
                  final statut = s['statut']?.toLowerCase() ?? '';
                  return statut == 'planifiée' || statut == 'en cours';
                }).toList();

                if (seances.isNotEmpty) {
                  groupedSeances[titreFormation] = seances;
                }
              }

              if (groupedSeances.isEmpty) {
                return const Center(
                    child: Text('Aucune séance planifiée/en cours.'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: groupedSeances.entries.map((entry) {
                  final titre = entry.key;
                  final seances = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: OleaColors.oleaPrimaryReddishOrange, // Use Olea primary color
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...seances.map((s) => _buildSeanceCard(s)).toList(),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSeanceCard(Map<String, dynamic> seance) {
    final date = (seance['date'] as Timestamp?)?.toDate();
    final heureDebut = seance['heureDebut'] ?? '';
    final heureFin = seance['heureFin'] ?? '';
    final titre = seance['titre'] ?? '';
    final statut = seance['statut'] ?? 'inconnu';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.event_note, color: OleaColors.oleaSecondaryBrown), // Icon color
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date != null
                ? DateFormat('dd/MM/yyyy').format(date)
                : 'Date inconnue'),
            Text('$heureDebut → $heureFin'),
            Text(
              'Statut : $statut',
              style: TextStyle(
                color: statut == 'En Cours'
                    ? OleaColors.oleaPrimaryOrange // 'En Cours' status color
                    : OleaColors.oleaPrimaryReddishOrange, // Other status color
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}