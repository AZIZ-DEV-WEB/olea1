// lib/pages/crud/edit_event_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:date_field/date_field.dart';

class EditEventPage extends StatefulWidget {
  final String docId;
  final String confName;
  final String sujet;
  final String type;
  final String avatar;
  final DateTime date;

  const EditEventPage({
    super.key,
    required this.docId,
    required this.confName,
    required this.sujet,
    required this.type,
    required this.avatar,
    required this.date,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  bool _hasChanged = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController confNameController;
  late TextEditingController sujetController;
  late TextEditingController avatarController;
  late String selectedType;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    confNameController = TextEditingController(text: widget.confName);
    sujetController = TextEditingController(text: widget.sujet);
    avatarController = TextEditingController(text: widget.avatar);
    selectedType = widget.type;
    selectedDate = widget.date;
    confNameController.addListener(_checkIfChanged);
    sujetController.addListener(_checkIfChanged);
    avatarController.addListener(_checkIfChanged);


  }
  //la fonction pour detecter si
  void _checkIfChanged() {
    setState(() {
      _hasChanged =
          confNameController.text != widget.confName ||
              sujetController.text != widget.sujet ||
              avatarController.text != widget.avatar ||
              selectedType != widget.type ||
              selectedDate != widget.date;
    });
  }

  @override
  void dispose() {
    confNameController.dispose();
    sujetController.dispose();
    avatarController.dispose();
    super.dispose();
  }

  void updateEvent() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection("Events")
          .doc(widget.docId)
          .update({
        'confName': confNameController.text,
        'sujet': sujetController.text,
        'avatar': avatarController.text,
        'type': selectedType,
        'date': selectedDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Modification réussie")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier la conférence")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: confNameController,
                decoration: InputDecoration(labelText: "Nom de la conférence"),
                validator: (val) => val == null || val.isEmpty ? "Obligatoire" : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: sujetController,
                decoration: InputDecoration(labelText: "Sujet"),
                validator: (val) => val == null || val.isEmpty ? "Obligatoire" : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: avatarController,
                decoration: InputDecoration(labelText: "Avatar"),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: "talk", child: Text("Talk")),
                  DropdownMenuItem(value: "demo", child: Text("Demo")),
                  DropdownMenuItem(value: "partner", child: Text("Partner")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                    _checkIfChanged();
                  });
                },
                decoration: InputDecoration(labelText: "Type"),
              ),
              SizedBox(height: 8),
              DateTimeFormField(
                initialValue: selectedDate,
                onChanged: (val) {
                  selectedDate = val!;
                  _checkIfChanged(); // Appelle la fonction pour recalculer s’il y a eu un changement
                },
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _hasChanged ? updateEvent : null,
                child: Text("Enregistrer les modifications"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
