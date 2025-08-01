import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firstproject/utils/olea_colors.dart';

class UserHistoriquesFormationsPage extends StatefulWidget {
  const UserHistoriquesFormationsPage({super.key});

  @override
  State<UserHistoriquesFormationsPage> createState() =>
      _UserHistoriquesFormationsPageState();
}

class _UserHistoriquesFormationsPageState
    extends State<UserHistoriquesFormationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = '';
  String? selectedYear;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Utilisateur non connecté.'));
    }

    return Scaffold(
      backgroundColor: OleaColors.oleaLightBeige,
      appBar: AppBar(
        title: const Text("Historique de mes formations"),
        backgroundColor: OleaColors.oleaPrimaryReddishOrange,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher par titre',
                prefixIcon: Icon(Icons.search, color: OleaColors.oleaPrimaryDarkGray),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: OleaColors.oleaPrimaryDarkGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: OleaColors.oleaPrimaryOrange),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // 📅 Filtre par année
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: InputDecoration(
                labelText: 'Filtrer par année',
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: OleaColors.oleaPrimaryDarkGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: OleaColors.oleaPrimaryOrange),
                ),
              ),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year.toString(),
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) => setState(() => selectedYear = value),
            ),
          ),

          const SizedBox(height: 10),

          // 🔽 Liste des formations
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('participations')
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', whereIn: ['invited', 'rejected'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final participations = snapshot.data!.docs;

                if (participations.isEmpty) {
                  return const Center(child: Text('Aucune formation trouvée.'));
                }

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _getFormationsWithDetails(participations),
                  builder: (context, formationSnap) {
                    if (!formationSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final formations = formationSnap.data!;

                    final filtered = formations.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final titre = data['titre']?.toString().toLowerCase() ?? '';
                      final dateDebut = (data['dateDebut'] as Timestamp?)?.toDate();
                      final year = dateDebut != null ? dateDebut.year.toString() : '';

                      final matchTitre = titre.contains(searchQuery.toLowerCase());
                      final matchYear = selectedYear == null || selectedYear == year;

                      return matchTitre && matchYear;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text("Aucune formation trouvée selon vos critères."));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index].data() as Map<String, dynamic>;
                        final titre = data['titre'] ?? 'Sans titre';
                        final desc = data['description'] ?? '';
                        final organisme = data['organismenom'] ?? 'Inconnu';
                        final dateDebut = (data['dateDebut'] as Timestamp?)?.toDate();
                        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();

                        return Card(
                          color: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: OleaColors.oleaPrimaryOrange, width: 1.2),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre avec icône
                                Row(
                                  children: [
                                    Icon(Icons.school, color: OleaColors.oleaPrimaryDarkGray),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        titre,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: OleaColors.oleaPrimaryDarkGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Description
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.description, color: OleaColors.oleaPrimaryOrange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description : ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: OleaColors.oleaPrimaryDarkGray,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Organisme
                                Row(
                                  children: [
                                    Icon(Icons.business, color: OleaColors.oleaPrimaryOrange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Organisme : ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: OleaColors.oleaPrimaryDarkGray,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        organisme,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Dates
                                if (dateDebut != null || dateFin != null)
                                  Row(
                                    children: [
                                      if (dateDebut != null)
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 18, color: OleaColors.oleaPrimaryOrange),
                                            const SizedBox(width: 6),

                                            Text(
                                              'Début : ${DateFormat('dd/MM/yyyy').format(dateDebut)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: OleaColors.oleaPrimaryDarkGray,
                                              ),                                            ),
                                          ],
                                        ),
                                      const SizedBox(width: 20), // Petit espace entre les deux dates


                                      if (dateFin != null)

                                        Row(
                                          children: [
                                            Icon(Icons.event, size: 18, color: OleaColors.oleaPrimaryOrange),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Fin : ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: OleaColors.oleaPrimaryDarkGray,
                                              ),                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<DocumentSnapshot>> _getFormationsWithDetails(List<DocumentSnapshot> participations) async {
    final formationIds = participations.map((doc) => doc['formationId'] as String).toList();

    if (formationIds.isEmpty) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('formations')
        .where(FieldPath.documentId, whereIn: formationIds)
        .get();

    return querySnapshot.docs;
  }
}
