import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'FormationDetailsPage.dart';

class UserProchainesFormationsPage extends StatelessWidget {
  const UserProchainesFormationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    final participationsQuery = FirebaseFirestore.instance
        .collection('participations')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['invited']);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes prochaines formations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: participationsQuery.snapshots(),
        builder: (context, pSnap) {
          if (pSnap.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }
          if (pSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final participationDocs = pSnap.data!.docs;
          if (participationDocs.isEmpty) {
            return const Center(child: Text('Vous n’êtes invité à aucune formation'));
          }

          // ---- Liste des IDs de formation concernées
          final formationIds = participationDocs
              .map((d) => d['formationId'] as String)
              .toList();

          final formationsParticipation = participationDocs.map((doc) {
            return {
              'formationId': doc['formationId'] as String,
              'status': doc['status'] as String,
            };
          }).toList();


          // ---- ListView avec un StreamBuilder par formation
          return ListView.builder(
            itemCount: formationsParticipation.length,
            itemBuilder: (context, index) {
              final fp = formationsParticipation[index];
              final fid = fp['formationId'];
              final status = fp['status'];

              final DocumentReference formationRef =
              FirebaseFirestore.instance.collection('formations').doc(fid);

              return StreamBuilder<DocumentSnapshot>(
                stream: formationRef.snapshots(),
                builder: (context, fSnap) {
                  if (!fSnap.hasData) {
                    return const SizedBox.shrink(); // placeholder
                  }
                  final fData = fSnap.data!.data() as Map<String, dynamic>?;

                  // Cas où le doc a été supprimé :
                  if (fData == null) return const SizedBox.shrink();

                  // On filtre ici : on ne garde que les « planifiée »
                  if (fData['statut'] != 'Planifiée') {
                    return const SizedBox.shrink();
                  }

                  final title      = fData['titre'] ?? 'Sans titre';
                  final organismetitre = fData['organismenom'] ?? 'Sans organisme';




                  return Dismissible(
                    key: ValueKey(fid),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async => false, // on ne supprime pas vraiment
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.blueAccent, width: 1.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.school, color: Colors.blue),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Organisme : $organismetitre'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Statut : $status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'invited' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormationDetailPage(formationData: {
                                ...fData,
                                'id': fid,
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }



}
