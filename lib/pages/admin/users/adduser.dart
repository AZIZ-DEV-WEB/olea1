import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../services/auth.dart';
import '../../../widgets/department_dropdown.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog();

  @override
  State<AddUserDialog> createState() => AddUserDialogState();
}

class AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? department;
  final _posteCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvel utilisateur'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _userNameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Champ requis',
            ),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email invalide',
            ),
            const SizedBox(height: 10),
            DepartmentDropdown(

              selected: department,
              onChanged: (value) {
                setState(() {
                  department = value;
                });
              },
            ),
            const SizedBox(height: 10),
            //const SizedBox(height: 16),
            TextFormField(
              controller: _posteCtrl,
              decoration: const InputDecoration(labelText: 'Poste'),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Champ requis',
            ),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Au moins 6 caractères',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _loading = true);

                  try {
                    // ⬇️  appel au service d’authentification
                    final newUser = await AuthService().createUserAsAdmin(
                      username: _userNameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      password: _passwordCtrl.text.trim(),
                      department: department!.trim(),
                      poste: _posteCtrl.text.trim(),
                    );

                    if (!mounted) return;

                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _loading = false);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                    }
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}
