import 'package:flutter/material.dart';
import '../models/department.dart'; // Assurez-vous que ce chemin est correct

class DepartmentDropdown extends StatefulWidget {
  final String? selected;
  final void Function(String?) onChanged;

  const DepartmentDropdown({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DepartmentDropdown> createState() => _DepartmentDropdownState();
}

class _DepartmentDropdownState extends State<DepartmentDropdown> {
  final DepartmentService _service = DepartmentService();
  late Future<List<String>> _departmentsFuture;

  // Couleurs OLEA définies
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaLightBeige = const Color(0xFFE3D9C0); // Non utilisée directement ici mais pour cohérence

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _service.getDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _departmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFB7482B), // Couleur OLEA pour le spinner
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Erreur de chargement des départements : ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            "Aucun département disponible.",
            style: TextStyle(color: Colors.grey),
          );
        }

        final departments = snapshot.data!;

        return DropdownButtonFormField<String>(
          value: widget.selected,
          items: departments.map((dep) {
            return DropdownMenuItem<String>(
              value: dep,
              child: Text(
                dep,
                overflow: TextOverflow.ellipsis, // Gère le débordement de texte
                maxLines: 1, // Assure que le texte reste sur une seule ligne
                style: TextStyle(color: oleaPrimaryDarkGray), // Texte des items OLEA
              ),
            );
          }).toList(),
          onChanged: widget.onChanged,
          icon: Icon(Icons.arrow_drop_down, color: oleaPrimaryReddishOrange), // Flèche OLEA
          decoration: InputDecoration(
            labelText: 'Département',
            labelStyle: TextStyle(color: oleaPrimaryDarkGray), // Label OLEA
            hintText: 'Département', // Hint text cohérent
            prefixIcon: Icon(
              Icons.account_tree_outlined,
              color: oleaPrimaryReddishOrange, // Icône OLEA
            ),
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
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8), // Fond unifié OLEA
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Padding unifié
          ),
          validator: (value) =>
          value == null || value.isEmpty ? 'Sélectionnez un département' : null,
        );
      },
    );
  }
}
