import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/auth.dart';
import '../../../models/user.dart';


const Color oleaPrimaryOrange = Color(0xFFFF9800);

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({Key? key}) : super(key: key);
  @override
  AdminNotificationsPageState createState() => AdminNotificationsPageState();
}
class AdminNotificationsPageState extends State<AdminNotificationsPage> {
  MyUser? _currentAdmin;
  bool _loadingAdmin = true;
  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
  }

  Future<void> _loadCurrentAdmin() async {
    final admin = await AuthService().getCurrentUserData();
    setState(() {
      _currentAdmin = admin;
      _loadingAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentAdmin == null) {
      return const Scaffold(
        body: Center(child: Text("Impossible de récupérer le profil admin.")),
      );
    }
    final adminName = _currentAdmin!.username;
    final adminUid = _currentAdmin!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Admin'),
        backgroundColor: oleaPrimaryOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverUid', isEqualTo: adminUid)
            //.orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune notification.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final formationId = data['formationId'] ?? '';
              final seen = data['seen'] ?? false;
              return Card(
                color: seen ? Colors.grey[200] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.notification_important),
                  title: Text(title),
                  subtitle: Text(body),
                  trailing: formationId.isNotEmpty
                      ? Tooltip(
                    message: 'Formation ID: $formationId',
                    child: const Icon(Icons.school),
                  )
                      : null,
                  onTap: () {
                    // Marquer comme lu
                    docs[i].reference.update({'seen': true});
                    // Éventuellement naviguer vers détail
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }


}
