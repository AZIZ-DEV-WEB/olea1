import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrganismesPage extends StatefulWidget {
  const AdminOrganismesPage({Key? key}) : super(key: key);

  @override
  State<AdminOrganismesPage> createState() => _AdminOrganismesPageState();
}

class _AdminOrganismesPageState extends State<AdminOrganismesPage> {
  final CollectionReference orgRef =
  FirebaseFirestore.instance.collection('organismesFormation');

  /* ────────────────────────────────
   * ============  ADD  =============
   * ──────────────────────────────── */
  Future<void> _addOrganisme() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvel organisme de formation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact (email / téléphone)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await orgRef.add({
                  'nom': nameCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'contact': contactCtrl.text.trim(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /* ────────────────────────────────
   * ============ EDIT ==============
   * ──────────────────────────────── */
  Future<void> _editOrganisme(String id, Map<String, dynamic> data) async {
    final nameCtrl    = TextEditingController(text: data['nom']);
    final addressCtrl = TextEditingController(text: data['address']);
    final contactCtrl = TextEditingController(text: data['contact']);
    final typeCtrl    = TextEditingController(text: data['type']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier l\'organisme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await orgRef.doc(id).update({
                  'nom': newName,
                  'address': addressCtrl.text.trim(),
                  'contact': contactCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /* ────────────────────────────────
   * =========== DELETE =============
   * ──────────────────────────────── */
  Future<void> _deleteOrganisme(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'organisme ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) await orgRef.doc(id).delete();
  }

  /* ────────────────────────────────
   * ============ BUILD =============
   * ──────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organismes de formation')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrganisme,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un organisme',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: orgRef.orderBy('nom').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Erreur de chargement'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Aucun organisme trouvé'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id   = docs[i].id;

              final name    = data['nom']    ?? 'Sans nom';
              final address = data['address'] ?? 'Adresse inconnue';
              final contact = data['contact'] ?? 'Contact non fourni';
              final type    = data['type']    ?? 'Type inconnu';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Row(
                    children: [
                      const Icon(Icons.business, size: 20, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: Text(address)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: Text(contact)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.info, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: Text(type)),
                            ],
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editOrganisme(id, data),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOrganisme(id),
                        tooltip: 'Supprimer',
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
