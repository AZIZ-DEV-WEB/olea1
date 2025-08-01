import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/organisme.dart'; // adapte ce chemin selon ton projet

class OrganismeDropdown extends StatefulWidget {
  final Function(OrganismeFormation) onChanged;
  final OrganismeFormation? selected;
  final InputDecoration? decoration;

  const OrganismeDropdown({
    super.key,
    required this.onChanged,
    this.selected,
    this.decoration,
    required String value,
  });

  @override
  State<OrganismeDropdown> createState() => _OrganismeDropdownState();
}

class _OrganismeDropdownState extends State<OrganismeDropdown> {
  late Future<List<OrganismeFormation>> _organismesFuture;
  OrganismeFormation? _selectedOrganisme;
  String? _selectedOrganismeId;

  @override
  void initState() {
    super.initState();
    _selectedOrganisme = widget.selected;
    _selectedOrganismeId = widget.selected?.id;
    _organismesFuture = fetchOrganismes();
  }

  Future<List<OrganismeFormation>> fetchOrganismes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('organismesFormation')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => OrganismeFormation.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrganismeFormation>>(
      future: _organismesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Erreur : ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("Aucun organisme disponible");
        }

        final organismes = snapshot.data!;

        return DropdownButtonFormField<String>(
          value: _selectedOrganismeId,
          items: organismes.map((organisme) {
            return DropdownMenuItem(
              value: organisme.id,
              child: Text(organisme.nom),
            );
          }).toList(),
          onChanged: (String? id) {
            setState(() {
              _selectedOrganismeId = id;
              _selectedOrganisme = organismes.firstWhere((o) => o.id == id);
            });
            widget.onChanged(_selectedOrganisme!);
          },
          decoration: widget.decoration ??
              InputDecoration(
                labelText: 'Organisme',
                prefixIcon: const Icon(Icons.apartment_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        );
      },
    );
  }
}
