import 'package:flutter/material.dart';

class DropdownModalite extends StatelessWidget {
  final String? selectedValue;
  final void Function(String?) onChanged;

  const DropdownModalite(
      {
    Key? key,
    required this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

  final List<Map<String, dynamic>> modalites = const [
    {'nom': 'Présentiel'},
    {'nom': 'Distanciel'},
    {'nom': 'Blended-learning'},
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: 'Modalité',
        prefixIcon: Icon(Icons.computer),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: modalites.map((mod) {
        return DropdownMenuItem<String>(
          value: mod['nom'],
          child: Text(mod['nom']),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) =>
      value == null || value.isEmpty ? 'Veuillez choisir une modalité' : null,
    );
  }
}
