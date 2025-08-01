import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserFormationsDisponiblesPage extends StatefulWidget {
  const UserFormationsDisponiblesPage({super.key});

  @override
  State<UserFormationsDisponiblesPage> createState() =>
      _userFormationsDisponiblesPageState();
}

class _userFormationsDisponiblesPageState
    extends State<UserFormationsDisponiblesPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  Set<String> _participatedFormationIds = {};

  @override
  void initState() {
    super.initState();
    _loadParticipations();
  }

  Future<void> _loadParticipations() async {
    final snap = await FirebaseFirestore.instance
        .collection('participations')
        .where('userId', isEqualTo: uid)
        .get();
    setState(() {
      _participatedFormationIds = snap.docs
          .map((doc) => doc['formationId'].toString())
          .toSet();
    });
  }

  Future<List<DocumentSnapshot>> _fetchAvailableFormations() async {
    final allFormationsSnap = await FirebaseFirestore.instance
        .collection('formations')
        .get();

    return allFormationsSnap.docs.where((doc) {
      return !_participatedFormationIds.contains(doc.id);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formations disponibles')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchAvailableFormations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final formations = snapshot.data!;
          if (formations.isEmpty) {
            return const Center(child: Text('Aucune formation disponible.'));
          }

          return ListView.builder(
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final data = formations[index].data() as Map<String, dynamic>;
              final id = formations[index].id;
              final titre = data['titre'] ?? 'Sans titre';
              final description = data['description'] ?? '';

              bool participated = _participatedFormationIds.contains(id);

              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(description),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: participated
                                ? null
                                : () async {
                                    final userSnap = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(uid)
                                        .get();

                                    final username = userSnap['username'];
                                    final department = userSnap['department'];

                                    await FirebaseFirestore.instance
                                        .collection('participations')
                                        .add({
                                          'formationId': id,
                                          'formationtitle': titre,
                                          'department': department,
                                          'userName': username,
                                          'userId': uid,
                                          'status': 'invited',
                                        });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Participation enregistrée",
                                        ),
                                      ),
                                    );

                                    setState(() {
                                      _participatedFormationIds.add(id);
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Participer'),
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
      ),
    );
  }
}
