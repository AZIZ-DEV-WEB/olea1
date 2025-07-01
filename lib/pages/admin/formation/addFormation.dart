import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../widgets/custom_department_dropdown.dart';
import '../../../widgets/modalités.dart';
import '../../../widgets/organismes.dart';

class Addformation extends StatefulWidget {
  const Addformation({super.key});

  @override
  _AddformationState createState() => _AddformationState();
}

class _AddformationState extends State<Addformation> {
  DateTime? _dateFin;
  DateTime? _dateDebut;

  Map<String, Set<String>> _selectedUsers = {};
  List<Map<String, dynamic>> _calendrier = [];

  // Controllers pour le formulaire d'ajout
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  final _dureController = TextEditingController();
  String? _selectedModalite;
  String? _organismeId;

  @override
  void dispose() {
    // Libérer les controllers pour éviter fuite mémoire
    _titreController.dispose();
    _descriptionController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _dureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final fieldFontSize = isSmallScreen ? 14.0 : 16.0;
    final fieldVerticalPadding = isSmallScreen ? 8.0 : 12.0;
    final formPadding = isSmallScreen ? 12.0 : 20.0;

    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
        contentPadding: EdgeInsets.symmetric(
          vertical: fieldVerticalPadding,
          horizontal: 12,
        ),
      );
    }

    Future<void> _selectDateDebut(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2025, 12, 31),
      );
      if (picked != null) {
        setState(() {
          _dateDebut = picked; // on garde la vraie valeur DateTime
          _dateDebutController.text =
              "${picked.day}/${picked.month}/${picked.year}"; // juste pour l'affichage
        });
      }
    }

    Future<void> _selectDateFin(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2025, 12, 31),
      );
      if (picked != null) {
        setState(() {
          _dateFin = picked;
          _dateFinController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        });
      }
    }

    void _ajouterFormation() async {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedModalite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez une modalité')),
        );
        return;
      }
      if (_dateDebut != null &&
          _dateFin != null &&
          _dateDebut!.isAfter(_dateFin!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La date de début doit être antérieure à la date de fin',
            ),
          ),
        );
        return;
      }

      if (_selectedUsers.values.every((set) => set.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez au moins un participant')),
        );
        return;
      }

      final participants = _selectedUsers.entries
          .expand(
            (entry) => entry.value.map(
              (username) => {'username': username, 'department': entry.key},
            ),
          )
          .toList();

      final participantsCount = participants.length;

      try {
        final calendrierFirestore = _calendrier
            .map(
              (s) => {
                'date': Timestamp.fromDate(s['date']),
                'heureDebut': s['heureDebut'].format(context),
                'heureFin': s['heureFin'].format(context),
                'titre': s['titre'],
              },
            )
            .toList();

        final docRef = await FirebaseFirestore.instance
            .collection('formations')
            .add({
              'titre': _titreController.text.trim(),
              'description': _descriptionController.text.trim(),
              'statut': 'Planifiée',
              'createdAt': FieldValue.serverTimestamp(),
              'dateDebut': _dateDebutController.text.trim(),
              'dateFin': _dateFinController.text.trim(),
              'duré': _dureController.text.trim(),
              'modalite': _selectedModalite ?? '',
              'organismeId': _organismeId,
              'calendrier': calendrierFirestore,
              'participants': participants,
              'participantsCount': participantsCount,
            });

        final batch = FirebaseFirestore.instance.batch();

        for (final entry in _selectedUsers.entries) {
          final dept = entry.key;
          for (final username in entry.value) {
            final userSnap = await FirebaseFirestore.instance
                .collection('users')
                .where('username', isEqualTo: username)
                .limit(1)
                .get();

            final userId = userSnap.docs.isNotEmpty
                ? userSnap.docs.first.id
                : '';

            final partDoc = FirebaseFirestore.instance
                .collection('participations')
                .doc();
            batch.set(partDoc, {
              'formationId': docRef.id,
              'userId': userId,
              'userName': username,
              'department': dept,
              'status': 'invited',
            });
          }
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formation ajoutée avec succès')),
        );

        _formKey.currentState!.reset();
        _titreController.clear();
        _descriptionController.clear();
        _dateDebutController.clear();
        _dateFinController.clear();
        _dureController.clear();

        setState(() {
          _selectedUsers.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }

    // Le formulaire complet, repris de ton _buildAddFormationPage()
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une Formation')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(formPadding),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(formPadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Ligne 1
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _titreController,
                          style: TextStyle(fontSize: fieldFontSize),
                          decoration: inputDecoration(
                            'Titre de la formation',
                            Icons.title,
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Veuillez saisir un titre'
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dureController,
                          style: TextStyle(fontSize: fieldFontSize),
                          decoration: inputDecoration(
                            'Durée de la formation',
                            Icons.timer,
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Veuillez saisir une durée'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Ligne 2
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: TextStyle(fontSize: fieldFontSize),
                          decoration: inputDecoration(
                            'Description',
                            Icons.description,
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Veuillez saisir une description'
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setLocalState) {
                            return DropdownModalite(
                              selectedValue: _selectedModalite,
                              onChanged: (val) =>
                                  setLocalState(() => _selectedModalite = val),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Ligne 3
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateFinController,
                          style: TextStyle(fontSize: fieldFontSize),
                          decoration:
                              inputDecoration(
                                'Date de fin',
                                Icons.calendar_today,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.calendar_month),
                                  onPressed: () => _selectDateFin(context),
                                ),
                              ),
                          readOnly: true,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Veuillez sélectionner une date'
                              : null,
                        ),
                      ),

                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dateDebutController,
                          style: TextStyle(fontSize: fieldFontSize),
                          decoration:
                              inputDecoration(
                                'Date de début',
                                Icons.calendar_today,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.calendar_month),
                                  onPressed: () => _selectDateDebut(context),
                                ),
                              ),
                          readOnly: true,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Veuillez sélectionner une date'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Ligne 4
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.event_available),
                          label: const Text('Ajouter séance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade100,
                            foregroundColor: Colors.indigo.shade900,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(fontSize: fieldFontSize),
                          ),
                          onPressed:
                              _ouvrirPopupCalendrier, // à définir dans ton State
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OrganismeDropdown(
                          selectedId: _organismeId,
                          onChanged: (val) =>
                              setState(() => _organismeId = val),
                          validator: (val) => val == null
                              ? 'Choisissez un organisme de formation'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Ligne 5
                  DepartmentUserTable(
                    onChanged: (map) {
                      setState(() {
                        _selectedUsers = map;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _ajouterFormation,
                      icon: Icon(Icons.save, size: isSmallScreen ? 18 : 24),
                      label: Text(
                        'Ajouter la Formation',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthode à définir pour ouvrir la popup calendrier
  void _ouvrirPopupCalendrier() {
    // variables locales à la popup
    DateTime date = DateTime.now();
    TimeOfDay heureDebut = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay heureFin = const TimeOfDay(hour: 12, minute: 0);
    String titre = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // helpers internes
          Future<void> _pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) setStateDialog(() => date = picked);
          }

          Future<void> _pickTime({required bool debut}) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: debut ? heureDebut : heureFin,
            );
            if (picked != null) {
              setStateDialog(() {
                if (debut) {
                  heureDebut = picked;
                  // s’assure que fin ≥ début
                  if (heureFin.hour < picked.hour ||
                      (heureFin.hour == picked.hour &&
                          heureFin.minute <= picked.minute)) {
                    heureFin = picked.replacing(minute: picked.minute + 30);
                  }
                } else {
                  heureFin = picked;
                }
              });
            }
          }

          return AlertDialog(
            title: const Text('Nouvelle séance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------- Date --------
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(DateFormat('yyyy‑MM‑dd').format(date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),

                // -------- Heure début --------
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: Text('Début : ${heureDebut.format(context)}'),
                  onTap: () => _pickTime(debut: true),
                ),

                // -------- Heure fin --------
                ListTile(
                  leading: const Icon(Icons.stop),
                  title: Text('Fin    : ${heureFin.format(context)}'),
                  onTap: () => _pickTime(debut: false),
                ),

                // -------- Titre --------
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Titre / Salle (optionnel)',
                  ),
                  onChanged: (v) => titre = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  // validation simple : fin après début
                  final debutMinutes = heureDebut.hour * 60 + heureDebut.minute;
                  final finMinutes = heureFin.hour * 60 + heureFin.minute;
                  if (finMinutes <= debutMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Heure de fin avant l’heure de début'),
                      ),
                    );
                    return;
                  }
                  // ➜ ajoute la séance
                  setState(() {
                    _calendrier.add({
                      'date': date,
                      'heureDebut': heureDebut,
                      'heureFin': heureFin,
                      'titre': titre,
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // notifie le parent si besoin
      setState(() {}); // pour rafraîchir l’aperçu éventuel
    });
  }
}
