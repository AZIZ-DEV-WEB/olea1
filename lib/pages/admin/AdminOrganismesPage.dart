import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import pour FirebaseAuth
import '../../widgets/custom_app_bar.dart'; // Import de votre CustomAppBar
import '../../services/auth.dart'; // Import de votre AuthService pour la déconnexion

class AdminOrganismesPage extends StatefulWidget {
  const AdminOrganismesPage({Key? key}) : super(key: key);

  @override
  State<AdminOrganismesPage> createState() => _AdminOrganismesPageState();
}

class _AdminOrganismesPageState extends State<AdminOrganismesPage> {
  final CollectionReference orgRef =
  FirebaseFirestore.instance.collection('organismesFormation');

  String? _username; // Variable pour stocker le nom d'utilisateur
  String? currentUserRole; // Variable pour stocker le rôle de l'utilisateur
  bool _isLoading = true; // pour savoir si les données sont en train d'être chargées



  // Couleurs OLEA
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);

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
        title: Text(
          'Nouvel organisme de formation',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(nameCtrl, 'Nom'),
              const SizedBox(height: 12),
              _buildStyledTextField(addressCtrl, 'Adresse'),
              const SizedBox(height: 12),
              _buildStyledTextField(contactCtrl, 'Contact (email / téléphone)', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildStyledTextField(typeCtrl, 'Type'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: oleaPrimaryDarkGray)), // Bouton Annuler OLEA
          ),
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

  /* ────────────────────────────────
   * ============ EDIT ==============
   * ──────────────────────────────── */
  Future<void> _editOrganisme(String id, Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(text: data['nom']);
    final addressCtrl = TextEditingController(text: data['address']);
    final contactCtrl = TextEditingController(text: data['contact']);
    final typeCtrl = TextEditingController(text: data['type']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Modifier l\'organisme',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(nameCtrl, 'Nom'),
              const SizedBox(height: 12),
              _buildStyledTextField(addressCtrl, 'Adresse'),
              const SizedBox(height: 12),
              _buildStyledTextField(contactCtrl, 'Contact', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildStyledTextField(typeCtrl, 'Type'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: oleaPrimaryDarkGray)), // Bouton Annuler OLEA
          ),
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
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: oleaPrimaryReddishOrange, // Bouton Enregistrer OLEA
              foregroundColor: Colors.white,
            ),
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
        title: Text(
          'Supprimer l\'organisme ?',
          style: TextStyle(color: oleaSecondaryDarkBrown), // Titre OLEA
        ),
        content: Text(
          'Cette action est irréversible.',
          style: TextStyle(color: oleaPrimaryDarkGray), // Texte OLEA
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: oleaPrimaryDarkGray)), // Bouton Annuler OLEA
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white), // Bouton Supprimer reste rouge
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) await orgRef.doc(id).delete();
  }

  // Helper method for consistent TextField styling
  Widget _buildStyledTextField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
        filled: true,
        fillColor: Colors.white.withOpacity(0.8), // Fond OLEA
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2), // Focus OLEA
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fonction pour charger le nom d'utilisateur
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

  /* ────────────────────────────────
   * ============ BUILD =============
   * ──────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: oleaLightBeige, // Fond de la page OLEA
      appBar: CustomAppBar( // Utilisation de CustomAppBar
        username: _username,
        getAppBarTitle: () => 'Organismes de formation', // Titre spécifique
        onLogout: () async {
          await AuthService().signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },

      ),
      floatingActionButton: currentUserRole == 'superadmin'
          ? FloatingActionButton(
        onPressed: _addOrganisme,
        backgroundColor: oleaPrimaryReddishOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un organisme',
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: orgRef.orderBy('nom').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text('Erreur de chargement: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: oleaPrimaryReddishOrange)); // Spinner OLEA
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
                child: Text('Aucun organisme trouvé',
                    style: TextStyle(color: oleaPrimaryDarkGray))); // Texte OLEA
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;

              final name = data['nom'] ?? 'Sans nom';
              final address = data['address'] ?? 'Adresse inconnue';
              final contact = data['contact'] ?? 'Contact non fourni';
              final type = data['type'] ?? 'Type inconnu';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Colors.white.withOpacity(0.95), // Fond de carte légèrement transparent
                child: ListTile(
                  title: Row(
                    children: [
                      Icon(Icons.business, size: 20, color: oleaPrimaryReddishOrange), // Icône OLEA
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: oleaSecondaryDarkBrown), // Titre OLEA
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
                            Icon(Icons.location_on, size: 18, color: oleaPrimaryDarkGray), // Icône OLEA
                            const SizedBox(width: 6),
                            Expanded(child: Text(address, style: TextStyle(color: oleaPrimaryDarkGray))), // Texte OLEA
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 18, color: oleaPrimaryDarkGray), // Icône OLEA
                            const SizedBox(width: 6),
                            Expanded(child: Text(contact, style: TextStyle(color: oleaPrimaryDarkGray))), // Texte OLEA
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info, size: 18, color: oleaPrimaryDarkGray), // Icône OLEA
                            const SizedBox(width: 6),
                            Expanded(child: Text(type, style: TextStyle(color: oleaPrimaryDarkGray))), // Texte OLEA
                          ],
                        ),
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: currentUserRole == 'superadmin'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: oleaPrimaryReddishOrange),
                        onPressed: () => _editOrganisme(id, data),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOrganisme(id),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
