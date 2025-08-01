import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'FormationDetailPage.dart';

class FormationsEnCoursPage extends StatelessWidget {
  const FormationsEnCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations en Cours'),
        backgroundColor: const Color(0xFFF8AF3C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('formations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement.'));
          }

          final formations = snapshot.data!.docs
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
              .where((formation) => formation['statut'] == 'En Cours')
              .toList();

          if (formations.isEmpty) {
            return const Center(child: Text('Aucune formation en cours.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final formation = formations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child:
                ListTile(
                  title: Text(formation['titre'] ?? 'Sans titre'),
                  subtitle: Text(formation['description'] ?? ''),
                  trailing: const Icon(Icons.schedule, color: Colors.blueGrey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminFormationDetailPage(formationData: formation),
                      ),
                    );
                  },
                ),              );

            },
          );
        },
      ),
    );
  }
}
