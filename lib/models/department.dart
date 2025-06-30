import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDepartments() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('departments').get();
      return snapshot.docs.map((doc) => doc['name'].toString()).toList();
    } catch (e) {
      print('Erreur chargement départements : $e');
      return [];
    }
  }
}
