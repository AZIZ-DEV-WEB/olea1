import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../../services/auth.dart';
import '../../../widgets/department_dropdown.dart';

class EditUserDialog extends StatefulWidget {
  final MyUser user;
  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _userNameCtrl;
  String? _departmentCtrl; // Changed to String?
  late final TextEditingController _posteCtrl;
  late final TextEditingController _roleCtrl;
  // Removed _photoUrlCtrl as it's not used for text input
  DateTime datetime = DateTime.now(); // This datetime is not used for user update

  // Couleurs OLEA
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user.email);
    _userNameCtrl = TextEditingController(text: widget.user.username);
    _departmentCtrl = widget.user.department; // Initialize with user's department
    _posteCtrl = TextEditingController(text: widget.user.poste);
    _roleCtrl = TextEditingController(text: widget.user.role);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userNameCtrl.dispose();
    _posteCtrl.dispose();
    _roleCtrl.dispose();
    // _photoUrlCtrl.dispose(); // No longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier utilisateur', style: TextStyle(color: oleaSecondaryDarkBrown)), // Titre OLEA
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            minWidth: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(
                controller: _userNameCtrl,
                label: 'Nom',
                hint: 'Entrez le nom',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),

              _buildStyledTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'Entrez l\'email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // Email should generally be read-only for existing users
              ),
              const SizedBox(height: 12),

              DepartmentDropdown(
                selected: _departmentCtrl,
                onChanged: (value) {
                  setState(() => _departmentCtrl = value);
                },
              ),
              const SizedBox(height: 12),

              _buildStyledTextField(
                controller: _posteCtrl,
                label: 'Poste',
                hint: 'Entrez le poste',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _roleCtrl.text.isEmpty ? null : _roleCtrl.text, // Handle empty string for initial value
                items: ['user', 'admin', 'superadmin'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase(), style: TextStyle(color: oleaPrimaryDarkGray)), // Texte OLEA
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _roleCtrl.text = val!; // Update controller text
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Rôle',
                  labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: oleaPrimaryReddishOrange), // Icône OLEA
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
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () async {
                  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image == null) return;

                  final file = File(image.path);
                  // Vous devrez implémenter la logique de téléchargement de l'image vers Firebase Storage ici
                  // et mettre à jour le photoUrl de l'utilisateur dans Firestore.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logique de téléchargement d\'image à implémenter')),
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choisir une image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: oleaPrimaryReddishOrange, // Bouton OLEA
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler',
            style: TextStyle(color: oleaPrimaryDarkGray), // Bouton Annuler OLEA
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedUser = MyUser(
              uid: widget.user.uid,
              username: _userNameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              department: _departmentCtrl?.trim() ?? '',
              poste: _posteCtrl.text.trim(),
              role: _roleCtrl.text.trim(),
              joinDate: widget.user.joinDate, // Conserver la date d'adhésion existante
              photoUrl: widget.user.photoUrl, // Conserver l'URL de la photo existante
              emailVerified: widget.user.emailVerified, // Conserver l'état de vérification de l'email
            );
            await AuthService().updateUser(updatedUser);
            if (mounted) Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: oleaPrimaryReddishOrange, // Bouton Enregistrer OLEA
            foregroundColor: Colors.white,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool readOnly = false, // Ajout de la propriété readOnly
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly, // Applique la propriété readOnly
      style: TextStyle(
        color: readOnly ? oleaPrimaryDarkGray : Colors.black87, // Couleur du texte pour lecture seule
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: oleaPrimaryReddishOrange) : null, // Icône OLEA
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
      ),
    );
  }
}
