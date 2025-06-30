import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'crud/edit_event_event_page.dart';

class eventpage extends StatefulWidget {
  const eventpage({super.key});

  @override
  State<eventpage> createState() => _eventpageState();
}

class _eventpageState extends State<eventpage> {
  // Fonction pour supprimer un document de Firestore
  void deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection("Events").doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Conférence supprimée")),
    );
  }
  final events = [];
  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Events").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (!snapshot.hasData) {
            return Text("Pas de Conférences");
          }
          List<dynamic> events = [];
          snapshot.data!.docs.forEach((element) {
            events.add(element);
          });

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final confName = event['confName'];
              final avatar = event['avatar'].toString().toLowerCase();
              final sujet = event['sujet'];
              final Timestamp timestamp = event['date'];
              final String date = DateFormat.yMd().add_jm().format(
                timestamp.toDate(),
              );

              return Card(
                child: ListTile(
                  leading: Image.asset(
                    "assets/images/$avatar.jpeg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text("$sujet:"),
                  subtitle: Text("$date"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_red_eye),
                        tooltip: 'Voir',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Détails de la conférence'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nom : ${event['confName']}'),
                                  Text('Sujet : ${event['sujet']}'),
                                  Text('Type : ${event['type']}'),
                                  Text('Date : ${DateFormat.yMd().add_jm().format((event['date'] as Timestamp).toDate())}'),
                                  Image.asset(
                                    "assets/images/${event['avatar'].toString().toLowerCase()}.jpeg",
                                    width: 250,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Fermer'),
                                  onPressed: () => Navigator.of(context).pop(),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: "Modifier",
                          // TODO : ouvrir un formulaire de modification (à implémenter plus tard)
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditEventPage(
                                  docId: event.id,
                                  confName: event['confName'],
                                  sujet: event['sujet'],
                                  type: event['type'],
                                  avatar: event['avatar'],
                                  date: (event['date'] as Timestamp).toDate(),
                                ),
                              ),
                            );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: "Supprimer",
                        onPressed: () {
                          // Confirmation de suppression
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirmer la suppression"),
                              content: Text(
                                "Voulez-vous vraiment supprimer cette conférence ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Annuler"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    deleteEvent(event.id); // Supprime par ID
                                  },
                                  child: Text("Supprimer"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
