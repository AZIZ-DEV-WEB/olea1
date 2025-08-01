import 'package:firstproject/utils/olea_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'FormationDetailPage.dart';


// À adapter selon ta couleur de thème
const Color oleaPrimaryDarkGray = Color(0xFF666666);

class FormationsTermineesPage extends StatelessWidget {
  const FormationsTermineesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations Terminées'),
        backgroundColor: OleaColors.oleaPrimaryReddishOrange,
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune formation trouvée.'));
          }

          final formations = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).where((formation) => formation['statut'] == 'Terminée').toList();

          if (formations.isEmpty) {
            return const Center(child: Text('Aucune formation terminée.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final formation = formations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(formation['titre'] ?? 'Sans titre'),
                  subtitle: Text(formation['description'] ?? ''),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminFormationDetailPage(formationData: formation),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
