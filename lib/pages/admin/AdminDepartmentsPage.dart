import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour FirebaseAuth
import '../../widgets/custom_app_bar.dart'; // Import de votre CustomAppBar
import '../../services/auth.dart'; // Import de votre AuthService pour la déconnexion

class AdminDepartmentsPage extends StatefulWidget {
  const AdminDepartmentsPage({Key? key}) : super(key: key);

  @override
  State<AdminDepartmentsPage> createState() => _AdminDepartmentsPageState();
}

class _AdminDepartmentsPageState extends State<AdminDepartmentsPage> {
  final CollectionReference departmentsRef = FirebaseFirestore.instance
      .collection('departments');

  String? _username; // Variable pour stocker le nom d'utilisateur
  String? currentUserRole;
  bool _isLoading = true; // pour savoir si les données sont en train d'être chargées

  // Couleurs OLEA
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() {
          currentUserRole = userDoc.data()?['role'];
          _username = userDoc.data()?['username'];
          _isLoading = false; // données chargées
        });
      } else {
        setState(() {
          _isLoading = false; // données chargées
        });
      }
    }
  }

  // Fonction pour charger le nom d'utilisateur

  Future<void> _addDepartment() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController responsableController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajouter un département',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du département',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responsableController,
                decoration: InputDecoration(
                  labelText: 'Responsable',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: oleaPrimaryDarkGray,
              ), // Bouton Annuler OLEA
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final responsable = responsableController.text.trim();

              if (name.isNotEmpty) {
                await departmentsRef.add({
                  'name': name,
                  'description': description,
                  'responsable': responsable,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: oleaPrimaryReddishOrange, // Bouton Ajouter OLEA
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDepartment(
    String id,
    Map<String, dynamic> currentData,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: currentData['name'],
    );
    final TextEditingController descriptionController = TextEditingController(
      text: currentData['description'],
    );
    final TextEditingController responsableController = TextEditingController(
      text: currentData['responsable'],
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modifier le département',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du département',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responsableController,
                decoration: InputDecoration(
                  labelText: 'Responsable',
                  labelStyle: TextStyle(
                    color: oleaPrimaryDarkGray,
                  ), // Label OLEA
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: oleaPrimaryReddishOrange,
                      width: 2,
                    ), // Focus OLEA
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: oleaPrimaryDarkGray,
              ), // Bouton Annuler OLEA
            ),
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
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  oleaPrimaryReddishOrange, // Bouton Enregistrer OLEA
              foregroundColor: Colors.white,
            ),
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
        title: Text(
          'Supprimer le département ?',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce département ? Cette action est irréversible.',
          style: TextStyle(color: oleaPrimaryDarkGray), // Texte OLEA
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: oleaPrimaryDarkGray,
              ), // Bouton Annuler OLEA
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red, // Conserver le rouge pour la suppression
              foregroundColor: Colors.white,
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
      backgroundColor: oleaLightBeige, // Fond de la page OLEA
      appBar: CustomAppBar(
        // Utilisation de CustomAppBar
        username: _username,
        getAppBarTitle: () =>
            'Gestion des départements', // Titre spécifique à cette page
        onLogout: () async {
          await AuthService().signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
      ),
      floatingActionButton: !_isLoading && currentUserRole == 'superadmin'
          ? FloatingActionButton(
              onPressed: _addDepartment,
              backgroundColor: oleaPrimaryReddishOrange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              tooltip: 'Ajouter un département',
            )
          : null,

      body: StreamBuilder<QuerySnapshot>(
        stream: departmentsRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: oleaPrimaryReddishOrange),
            ); // Spinner OLEA
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'Aucun département trouvé',
                style: TextStyle(color: oleaPrimaryDarkGray), // Texte OLEA
              ),
            );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white.withOpacity(
                    0.95,
                  ), // Fond de carte légèrement transparent
                  child: ListTile(
                    title: Text(
                      deptName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: oleaSecondaryDarkBrown,
                      ), // Titre OLEA
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Resp. : $deptResponsable\n$deptDescription',
                        style: TextStyle(
                          color: oleaPrimaryDarkGray,
                        ), // Sous-titre OLEA
                      ),
                    ),
                    isThreeLine: true,

                    trailing: currentUserRole == 'superadmin'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: oleaPrimaryReddishOrange,
                                ), // Icône Modifier OLEA
                                onPressed: () => _editDepartment(doc.id, data),
                                tooltip: 'Modifier',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ), // Icône Supprimer reste rouge
                                onPressed: () => _deleteDepartment(deptId),
                                tooltip: 'Supprimer',
                              ),
                            ],
                          )
                        : null,
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
