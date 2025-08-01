import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceHelper {
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifie si un deviceId est déjà stocké
    String? storedId = prefs.getString('deviceId');
    if (storedId != null) return storedId;

    // Sinon, génère un nouveau UUID et le sauvegarde
    String newId = const Uuid().v4();
    await prefs.setString('deviceId', newId);
    return newId;
  }
}
