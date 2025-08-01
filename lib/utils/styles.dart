import 'package:flutter/material.dart';

import '../pages/admin/DemandesFormation/AdminPendingRequests.dart';
import '../pages/user/DemandesFormations/DeposerDemande.dart' hide oleaPrimaryReddishOrange, oleaLightBeige;

class AppColors {
  static const Color orange = Color(0xFFF8AF3C);     // Orange OLEA
  static const Color darkRed = Color(0xFFB7482B);    // Rouge foncé OLEA
  static const Color darkGray = Color(0xFF666666);   // Gris foncé OLEA
}

InputDecoration commonDropdownDecoration({
  required String label,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontWeight: FontWeight.w600, // en gras
      color: Colors.black,
    ),
    filled: true,
    fillColor: oleaLightBeige.withOpacity(.35),
    prefixIcon: icon != null ? Icon(icon, color: oleaPrimaryReddishOrange) : null,
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
}

