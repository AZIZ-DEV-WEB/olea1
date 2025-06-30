import 'package:firstproject/pages/acceuil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../add_event_page.dart';
import '../eventpage.dart';




class Userhomepage extends StatefulWidget {
  const Userhomepage({super.key});

  @override
  State<Userhomepage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<Userhomepage> {
  int _currentIndex = 0;

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: [
          Text(""),
          Text("Liste des Conférences"),
          Text("Formulaire"),
        ][_currentIndex],
      ),
      body: [
        acceuil(),
        eventpage(),
        AddEventPage()
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setCurrentIndex(index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        iconSize: 32,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Accueil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Planning",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Ajout",
          ),
        ],
      ),
    );
  }
}
