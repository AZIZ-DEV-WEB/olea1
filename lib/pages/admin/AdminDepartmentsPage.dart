import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDepartmentsPage extends StatefulWidget {
  const AdminDepartmentsPage({Key? key}) : super(key: key);

  @override
  State<AdminDepartmentsPage> createState() => _AdminDepartmentsPageState();
}

class _AdminDepartmentsPageState extends State<AdminDepartmentsPage> {
  final CollectionReference departmentsRef =
  FirebaseFirestore.instance.collection('departments');

  Future<void> _addDepartment() async {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _responsableController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un département'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du département'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _responsableController,
                decoration: const InputDecoration(labelText: 'Responsable'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final description = _descriptionController.text.trim();
              final responsable = _responsableController.text.trim();

              if (name.isNotEmpty) {
                await departmentsRef.add({
                  'name': name,
                  'description': description,
                  'responsable': responsable,
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

  Future<void> _editDepartment(String id, Map<String, dynamic> currentData) async {
    final TextEditingController nameController =
    TextEditingController(text: currentData['name']);
    final TextEditingController descriptionController =
    TextEditingController(text: currentData['description']);
    final TextEditingController responsableController =
    TextEditingController(text: currentData['responsable']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le département'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du département'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responsableController,
                decoration: const InputDecoration(labelText: 'Responsable'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newDescription = descriptionController.text.trim();
              final newResponsable = responsableController.text.trim();

              if (newName.isNotEmpty) {
                await departmentsRef.doc(id).update({
                  'name': newName,
                  'description': newDescription,
                  'responsable': newResponsable,
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

  Future<void> _deleteDepartment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le département ?'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce département ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await departmentsRef.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des départements'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDepartment,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un département',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: departmentsRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun département trouvé'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final deptId = doc.id;
              final deptName = data['name'] ?? 'Sans nom';
              final deptResponsable = data['responsable'] ?? 'Sans responsable';
              final deptDescription = data['description'] ?? 'Sans description';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(deptName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Resp. : $deptResponsable\n$deptDescription'),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editDepartment(doc.id, data),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDepartment(deptId),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
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
