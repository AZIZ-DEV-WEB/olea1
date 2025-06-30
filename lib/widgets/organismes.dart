import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// -------------------------------------------------------------------------
///  DROPDOWN ORGANISMES  –  usage :
///
///  OrganismeDropdown(
///     selectedId: _organismeId,
///     onChanged : (val) => setState(() => _organismeId = val),
///     validator  : (val) =>
///       val == null ? 'Choisissez un organisme' : null,
///  )
/// -------------------------------------------------------------------------
class OrganismeDropdown extends StatelessWidget {
  final String? selectedId;
  // documentId sélectionné
  final void Function(String?) onChanged;        // callback à chaque change
  final String? Function(String?)? validator;    // validation du formulaire

  const OrganismeDropdown({
    Key? key,
    required this.selectedId,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 🔎 1. Écoute en temps réel la collection
      stream: FirebaseFirestore.instance
          .collection('organismesFormation')
      //.where('active', isEqualTo: true)           // optionnel : filtrer actifs
          .orderBy('nom')
          .snapshots(),
      builder: (context, snapshot) {
        // ---------- États d’attente / erreur ----------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Erreur de chargement des organismes');
        }

        // ---------- Conversion des documents ----------
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text('Aucun organisme de formation trouvé');
        }

        return DropdownButtonFormField<String>(
          value: selectedId,                         // valeur actuelle
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Organisme de formation',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
          items: docs.map((doc) {
            final name = doc['nom'] ?? 'Sans nom';
            return DropdownMenuItem<String>(
              value: doc.id,                         // stocke l’id Firestore
              child: Text(name),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        );
      },
    );
  }
}