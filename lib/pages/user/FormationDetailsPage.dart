import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'UserCourses.dart';

class FormationDetailPage extends StatelessWidget {
  final Map<String, dynamic> formationData;

  const FormationDetailPage({super.key, required this.formationData});

  @override
  Widget build(BuildContext context) {
    final formationId = formationData['id']; // il faut que tu passes aussi l'id dans `formationData`
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final title = formationData['titre'] ?? 'Sans titre';
    final description = formationData['description'] ?? 'Pas de description';
    final duree = formationData['duré'] ?? 'Inconnue';
    final organisme = formationData['organismenom'] ?? 'Inconnu';
    final modalite = formationData['modalite'] ?? 'Inconnue';

    final rawDateDebut = formationData['dateDebut'];
    final rawDateFin = formationData['dateFin'];

    final dateDebut = _parseToDate(rawDateDebut);
    final dateFin = _parseToDate(rawDateFin);
    final periode = '${_formatDate(dateDebut)} au ${_formatDate(dateFin)}';


    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView( // <-- Parenthèse ouvrante ici
        child: Padding( // <-- Le child de SingleChildScrollView est un Padding
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text('Période : $periode',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.timelapse, size: 18, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text('Durée : $duree heures',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.domain, size: 18, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text('Organisme : $organisme',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.style, size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text('Modalité : $modalite',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(description, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 16),
              const Text(
                'Séances programmées',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              if (formationData['calendrier'] != null &&
                  formationData['calendrier'] is List &&
                  (formationData['calendrier'] as List).isNotEmpty)
                ...List.generate(
                  (formationData['calendrier'] as List).length,
                      (index) {
                    final seance = formationData['calendrier'][index];
                    final date = seance['date'] is Timestamp
                        ? (seance['date'] as Timestamp).toDate()
                        : null;
                    final heureDebut = seance['heureDebut'] ?? '';
                    final heureFin = seance['heureFin'] ?? '';
                    final titreSeance = seance['titre'] ?? ''; // Renamed for clarity

                    return ListTile(
                      leading: const Icon(Icons.event_note, color: Colors.teal),
                      title: Text(titreSeance),
                      subtitle: Text(
                        '${_formatDate(date)} — $heureDebut à $heureFin',
                      ),
                    );
                  },
                )
              else
                const Text('Aucune séance programmée.'),
              const SizedBox(height: 16),

              // --- NOUVELLE PARTIE : LIEN VERS MES COURS ---
              Align( // Utiliser Align pour centrer le bouton si souhaité
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Centrer le contenu de la Row
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.class_), // Icône pour les cours
                        label: const Text(
                          'Voir mes cours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue, // Couleur du texte du lien
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MesCoursPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // --- FIN NOUVELLE PARTIE ---


              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('participations')
                    .where('userId', isEqualTo: userId)
                    .where('formationId', isEqualTo: formationId)
                    .limit(1)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.hourglass_empty),
                          label: const Text('Chargement...'),
                        ),
                      ],
                    );
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const SizedBox(); // pas encore d’invitation
                  }

                  final doc    = snap.data!.docs.first;
                  final status = doc['status'] as String;

                  switch (status) {
                    case 'invited':
                      return Center(
                        child: ElevatedButton.icon(
                          onPressed: null, // désactivé immédiatement
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text('Participé'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      );

                    case 'refused':
                      return Center(
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.cancel, color: Colors.white),
                          label: const Text('Refusé'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      );

                    default:
                      return const SizedBox();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _updateParticipationStatus(
      String formationId,
      String userId,
      String newStatus,
      BuildContext context, {
        String? refusalReason,
      }) async {
    // 1️⃣ Mise à jour du statut dans participations
    final query = await FirebaseFirestore.instance
        .collection('participations')
        .where('userId', isEqualTo: userId)
        .where('formationId', isEqualTo: formationId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return;
    await query.docs.first.reference.update({
      'status': newStatus,
      if (refusalReason != null) 'refusalReason': refusalReason,
    });

    // 2️⃣ Récupérer l’admin créateur depuis la formation
    final formationSnap = await FirebaseFirestore.instance
        .collection('formations')
        .doc(formationId)
        .get();
    if (!formationSnap.exists) return;
    final data = formationSnap.data()!;
    final String? adminUid   = data['createdByUid']   as String?;
    final String? adminName  = data['createdByName']  as String?;
    final String  titreForm  = data['titre']         as String? ?? '« Ta formation »';

    // 3️⃣ Enregistrer la notification pour l’admin
    if (adminUid != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverUid': adminUid,
        'receiverName': adminName ?? '',
        'title': newStatus == 'accepted'
            ? 'Participation acceptée'
            : 'Participation refusée',
        'body': newStatus == 'accepted'
            ? 'Un utilisateur a accepté votre invitation pour $titreForm.'
            : 'Un utilisateur a refusé votre invitation pour $titreForm.',
        'formationId': formationId,
        'seen': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // 4️⃣ Feedback à l’utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'accepted'
            ? 'Vous avez accepté la participation.'
            : 'Votre refus a bien été enregistré.'),
      ),
    );
  }



  void _showRefusalDialog(BuildContext context, String formationId, String userId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Entrez le motif de refus',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context); // fermer dialog
                _updateParticipationStatus(
                  formationId,
                  userId,
                  'refused',
                  context,
                  refusalReason: reason,
                );
              }
            },
            child: const Text('Confirmer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }


  DateTime? _parseToDate(dynamic input) {
    if (input is Timestamp) return input.toDate();
    if (input is String) {
      try {
        // Essaye de parser avec format personnalisé "dd/MM/yyyy"
        return DateFormat('dd/MM/yyyy').parseStrict(input);
      } catch (_) {
        try {
          // Si échoue, essaye le format ISO standard
          return DateTime.tryParse(input);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }


  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }


}
