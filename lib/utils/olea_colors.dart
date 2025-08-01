import 'package:flutter/material.dart';

class OleaColors {
  static Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  static Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  static Color oleaSecondaryBrown = const Color(0xFF936037);
  static Color oleaPrimaryDarkGray = const Color(0xFF666666);
  static Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  static Color oleaLightBeige = const Color(0xFFE3D9C0);

  InputDecoration oleaInput(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600, // label en gras
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

}
