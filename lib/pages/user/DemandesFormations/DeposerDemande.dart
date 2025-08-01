import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../services/auth.dart';
class RequestFormPage extends StatefulWidget {
  const RequestFormPage({super.key});

  @override
  _RequestFormPageState createState() => _RequestFormPageState();
}



final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
final Color oleaSecondaryBrown = const Color(0xFF936037);
final Color oleaPrimaryDarkGray = const Color(0xFF666666);
final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
final Color oleaLightBeige = const Color(0xFFE3D9C0);
InputDecoration oleaInput(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: TextStyle(
    fontWeight: FontWeight.w600,           // label en gras
    color: Colors.black,
  ),
  filled: true,
  fillColor: oleaLightBeige.withOpacity(.35),
  prefixIcon: Icon(icon, color: oleaPrimaryReddishOrange),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: oleaSecondaryBrown, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
);

class _RequestFormPageState extends State<RequestFormPage> {
  final AuthService _auth = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // tu n'as pas besoin de précharger ici, on récupère au moment du submit
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // 1) Récupère l'utilisateur courant
    final MyUser? currentUser = await _auth.getCurrentUserData();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion requise')),
      );
      return;
    }

    // 2) Prépare les données de la demande
    final requestData = {
      'userId': currentUser.uid,
      'userName': currentUser.username,
      'email': currentUser.email,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'createdAt': Timestamp.now(),
      'status': 'pending',
      'departement': currentUser.department,
      'poste': currentUser.poste,
      'adminComment': null,
      'departmentApproved': false,
    };

    // 3) Enregistre dans Firestore
    await FirebaseFirestore.instance
        .collection('formationRequests')
        .add(requestData);
    print(requestData);
    print("demande envoyé");

    // 4) Feedback et retour
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande envoyée')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('Nouvelle demande'),
      backgroundColor: oleaPrimaryReddishOrange,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration:
              oleaInput('Titre de la formation', Icons.title),
              validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration:
              oleaInput('Description du besoin', Icons.note),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
            ),
            const Divider(),
            SizedBox(
              width: 200, // Adjust this value as needed for your desired width
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oleaPrimaryOrange,
                ),
                onPressed: _submitRequest,
              ),
            )          ],
        ),
      ),
    ),
  );
}
