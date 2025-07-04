import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../../services/auth.dart';

class EditUserDialog extends StatefulWidget {
  final MyUser user;
  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _userNameCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _posteCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _photoUrlCtrl;
  DateTime datetime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user.email);
    _userNameCtrl = TextEditingController(text: widget.user.username);
    _departmentCtrl = TextEditingController(text: widget.user.department);
    _posteCtrl = TextEditingController(text: widget.user.poste);
    _roleCtrl = TextEditingController(text: widget.user.role);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userNameCtrl.dispose();
    _departmentCtrl.dispose();
    _posteCtrl.dispose();
    _roleCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier utilisateur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _userNameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _departmentCtrl,
              decoration: const InputDecoration(labelText: 'Département'),
            ),
            TextField(
              controller: _posteCtrl,
              decoration: const InputDecoration(labelText: 'Poste'),
            ),
            TextField(
              controller: _roleCtrl,
              decoration: const InputDecoration(labelText: 'Rôle'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image == null) return;

                // Ici tu peux gérer le fichier image, par exemple :
                final file = File(image.path);
                // Ensuite tu peux uploader, afficher, etc.
              },
              child: const Text('Choisir une image'),
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedUser = MyUser(
              uid: widget.user.uid,
              username: _userNameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              department: _departmentCtrl.text.trim(),
              poste: _posteCtrl.text.trim(),
              role: _roleCtrl.text.trim(),
              joinDate: datetime,
              photoUrl: '',
            );
            await AuthService().updateUser(updatedUser);
            Navigator.pop(context, true); // on retourne "true" pour signaler que c'est modifié
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
