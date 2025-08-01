import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firstproject/main.dart';

import '../../main.dart';
import 'FormationsdDisponibles.dart';
import 'ProchainesFormations.dart';

// Define OLEA colors here or in a separate theme file
const Color oleaPrimaryOrange = Color(0xFFFF9800); // A vibrant orange for OLEA

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    print("🟢 UID de l'utilisateur actuel : $currentUid");

    // Écoute en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📥 Notification en foreground : ${message.notification?.title}");
      showLocalNotification(
        message.notification?.title ?? 'No Title', // Default value if title is null
        message.notification?.body ?? 'No Body',
      );
    });
    // Tap sur la notification quand app est en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("👆 Notification cliquée (app en background)");
      // Rediriger vers page de formation si besoin
    });

    // Écoute en temps réel pour les nouvelles notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverUid', isEqualTo: currentUid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && !(data['seen'] ?? false)) {
            print("🔔 Nouvelle notification pour UID ${data['receiverUid']}");
            showLocalNotification(data['title'], data['body']);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: oleaPrimaryOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text(
                "data not found."));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucune notification pour le moment.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              final title = notif['title'] ?? 'Sans titre';
              final body = notif['body'] ?? '';
              final formationId = notif['formationId'] ?? '';
              final seen = notif['seen'] ?? false;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child:
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(title),
                  subtitle: Text(body),
                  trailing: formationId.isNotEmpty
                      ? Tooltip(
                    message: 'Formation ID : $formationId',
                    child: const Icon(Icons.school, color: Colors.blue),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserProchainesFormationsPage(),
                      ),
                    );
                  },
                )
              );
            },
          );
        },
      ),
    );
  }
}
