import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../admin/DemandesFormation/AdminPendingRequests.dart';

class DemandesEnAttente extends StatefulWidget {
  const DemandesEnAttente({super.key});

  @override
  State<DemandesEnAttente> createState() => _DemandesEnAttenteState();
}

class _DemandesEnAttenteState extends State<DemandesEnAttente> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _annulerDemande(String demandeId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment annuler cette demande ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Oui", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await FirebaseFirestore.instance
          .collection('formationRequests')
          .doc(demandeId)
          .delete();
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes en attente'),
        backgroundColor: oleaPrimaryReddishOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('formationRequests')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text("Erreur lors du chargement."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final demandes = snapshot.data!.docs;

          if (demandes.isEmpty) {
            return const Center(child: Text("Aucune demande en attente."));
          }



          return ListView.builder(
            itemCount: demandes.length,
            itemBuilder: (context, index) {
              final doc = demandes[index];
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Titre
                      Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: oleaSecondaryDarkBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(
                        data['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: oleaPrimaryDarkGray,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Bouton Annuler
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _annulerDemande(doc.id),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            'Annuler',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
