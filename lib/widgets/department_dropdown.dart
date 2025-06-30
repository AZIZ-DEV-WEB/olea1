import 'package:flutter/material.dart';
import '../models/department.dart'; // ton service Firestore

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
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("Erreur chargement départements");
        }

        final departments = snapshot.data!;

        return DropdownButtonFormField<String>(
          value: widget.selected,
          items: departments.map((dep) {
            return DropdownMenuItem<String>(
              value: dep,
              child: Text(dep),
            );
          }).toList(),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: 'Département',
            prefixIcon: const Icon(Icons.account_tree_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) =>
          value == null || value.isEmpty ? 'Sélectionnez un département' : null,
        );
      },
    );
  }
}
