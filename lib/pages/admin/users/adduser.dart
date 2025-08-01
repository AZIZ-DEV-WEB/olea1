import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../services/auth.dart';
import '../../../widgets/department_dropdown.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => AddUserDialogState();
}

class AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? department;
  String? role;
  final _posteCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  // Couleurs OLEA
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);


  @override
  void dispose() {
    _userNameCtrl.dispose();
    _emailCtrl.dispose();
    _posteCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Nouvel utilisateur',
        style: TextStyle(color: oleaSecondaryDarkBrown, fontWeight: FontWeight.bold), // Titre OLEA
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            minWidth: 300,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nom
                TextFormField(
                  controller: _userNameCtrl,
                  decoration: _inputDecoration('Nom', Icons.person_outline),
                  validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Champ requis',
                ),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                  validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 10),

                // Rôle Dropdown
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['user', 'admin', 'superadmin'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase(), style: TextStyle(color: oleaPrimaryDarkGray)), // Texte OLEA
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      role = val;
                    });
                  },
                  icon: Icon(Icons.arrow_drop_down, color: oleaPrimaryReddishOrange), // Flèche OLEA

                  decoration: InputDecoration(
                    labelText: 'Rôle',
                    labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
                    prefixIcon: Icon(Icons.account_circle_outlined, color: oleaPrimaryReddishOrange), // Icône OLEA
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8), // Fond OLEA
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  validator: (val) => val == null || val.isEmpty ? 'Sélectionnez un rôle' : null,
                ),

                const SizedBox(height: 10),

                // Département
                SizedBox(
                    child:DepartmentDropdown(
                      selected: department,
                      onChanged: (value) {
                        setState(() {
                          department = value;
                        });
                      },
                    ),
                ),
                const SizedBox(height: 10),

                // Poste
                TextFormField(
                  controller: _posteCtrl,
                  decoration: _inputDecoration('Poste', Icons.work_outline),
                  validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Champ requis',
                ),
                const SizedBox(height: 10),

                // Mot de passe
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration:
                  _inputDecoration('Mot de passe', Icons.lock_outline),
                  validator: (v) =>
                  v != null && v.length >= 6
                      ? null
                      : 'Au moins 6 caractères',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: Text(
            'Annuler',
            style: TextStyle(color: oleaPrimaryDarkGray), // Bouton Annuler OLEA
          ),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _loading = true);

            try {
              final success = await AuthService().registerWithEmailAndPassword(
                username: _userNameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text.trim(),
                department: department!.trim(),
                poste: _posteCtrl.text.trim(),
                role: role!.trim(),
                emailVerified: false, // Les utilisateurs ajoutés par admin doivent aussi vérifier leur email
              );
              if (!mounted) return;
              if (success) {
                Navigator.of(context).pop(true);
              } else {
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur lors de l\'ajout de l\'utilisateur. Vérifiez l\'email.')),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            }
          },
          child: _loading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: oleaPrimaryOrange, // Spinner OLEA
            ),
          )
              : Text(
            'Ajouter',
            style: TextStyle(color: oleaPrimaryReddishOrange), // Bouton Ajouter OLEA
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
      prefixIcon: Icon(icon, color: oleaPrimaryReddishOrange), // Icône OLEA
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
      filled: true,
      fillColor: Colors.white.withOpacity(0.8), // Fond OLEA
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }
}
