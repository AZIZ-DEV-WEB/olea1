import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/organisme.dart';
import '../../../models/user.dart';
import '../../../utils/styles.dart';
import '../../../widgets/custom_department_dropdown.dart';
import '../../../widgets/organismes.dart';
import '../../user/DemandesFormations/DeposerDemande.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class EditFormationPage extends StatefulWidget {
  final String formationId;
  final Map<String, dynamic> initialData;
  final List<Map<String, dynamic>> initialSeances;

  const EditFormationPage({
    super.key,
    required this.formationId,
    required this.initialData,
    required this.initialSeances,
  });

  @override
  State<EditFormationPage> createState() => _EditFormationPageState();
}

class _EditFormationPageState extends State<EditFormationPage> {
  late TextEditingController titreCtrl;
  late TextEditingController descCtrl;
  late String modalite;
  late String organismeNom;
  List<Map<String, dynamic>> calendrier = [];
  List<Map<String, dynamic>> mesCours = [];
  bool isUploadingCours = false;
  Map<String, Set<MyUser>> _selectedParticipants = {};
  OrganismeFormation? _selectedOrganisme;
  DateTime? dateDebut;
  DateTime? dateFin;





  @override
  void initState() {
    super.initState();
    titreCtrl = TextEditingController(text: widget.initialData['titre']);
    descCtrl = TextEditingController(text: widget.initialData['description']);
    modalite = widget.initialData['modalite'] ?? '';
    organismeNom = widget.initialData['organismenom'] ?? '';
    dateDebut = (widget.initialData['dateDebut'] as Timestamp?)?.toDate();
    dateFin = (widget.initialData['dateFin'] as Timestamp?)?.toDate();
    calendrier = List<Map<String, dynamic>>.from(widget.initialData['calendrier'] ?? []);
    mesCours = List<Map<String, dynamic>>.from(widget.initialData['mescours'] ?? []);
    final participantsData = widget.initialData['participants'] as List<dynamic>? ?? [];
    for (var pData in participantsData) {
      // Assuming pData contains enough info to construct a MyUser object
      // You might need to adjust this based on what's actually stored in Firestore
      final MyUser user = MyUser(
        uid: pData['uid'] ?? '', // Make sure UID is stored
        username: pData['username'] ?? '',
        department: pData['department'] ?? '',
        email: pData['email'] ?? '', // Add other fields as necessary
        poste: pData['poste'] ?? '',
        role: pData['role'] ?? '',
        photoUrl: pData['photoUrl'] ?? '',
        joinDate: (pData['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        emailVerified: pData['emailVerified'] as bool? ?? false,
      );
      _selectedParticipants.putIfAbsent(user.department, () => {}).add(user);

    }
  }



  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'Planifiée':
        return const Color(0xFFF8AF3C); // Orange OLEA
      case 'En cours':
        return const Color(0xFFB7482B); // Rouge foncé OLEA
      case 'Terminée':
        return const Color(0xFF666666); // Gris foncé OLEA
      default:
        return Colors.black45; // Couleur neutre par défaut
    }
  }



  Future<void> _selectDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => dateDebut = picked);
  }

  Future<void> _selectDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => dateFin = picked);
  }

  bool _validateDates() {
    final now = DateTime.now();

    if (dateDebut != null && dateDebut!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de début ne peut pas être dans le passé.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (dateDebut != null && dateFin != null) {
      if (dateFin!.isBefore(dateDebut!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La date de fin ne peut pas être avant la date de début.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  String calculerStatutFormation(DateTime? dateDebut, DateTime? dateFin) {
    final now = DateTime.now();

    if (dateDebut == null || dateFin == null) return 'Inconnue';

    if (now.isBefore(dateDebut)) {
      return 'Planifiée';
    } else if (now.isAfter(dateFin)) {
      return 'Terminée';
    } else {
      return 'En cours';
    }
  }




  Future<void> updateFormation() async {
    final List<Map<String, dynamic>> finalParticipants = _selectedParticipants.entries
        .expand((entry) =>
        entry.value.map((user) => {
          'username': user.username,
          'department': entry.key,
          'uid': user.uid,
          'email': user.email,
          'poste': user.poste,
          'role': user.role,
          'photoUrl': user.photoUrl,
          'joinDate': Timestamp.fromDate(user.joinDate),
          'emailVerified': user.emailVerified,
        })
    ).toList();

    if (!_validateDates()) return;

    await FirebaseFirestore.instance.collection('formations').doc(widget.formationId).update({
      'titre': titreCtrl.text,
      'description': descCtrl.text,
      'modalite': modalite,
      'statut': calculerStatutFormation(dateDebut, dateFin),
      'organismenom': _selectedOrganisme?.nom,
      'organismeId': _selectedOrganisme?.id,
      'calendrier': calendrier,
      'participants': finalParticipants, // Now storing MyUser data
      'dateDebut': dateDebut != null ? Timestamp.fromDate(dateDebut!) : null,
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
      'mescours': mesCours,



    });

    Navigator.pop(context);

  }

  void _editSeanceDialog(int index) {
    final seance = calendrier[index];
    final titreCtrl = TextEditingController(text: seance['titre']);
    DateTime? selectedDate = (seance['date'] as Timestamp).toDate();
    TimeOfDay? selectedStartTime = _parseTime(seance['heureDebut']);
    TimeOfDay? selectedEndTime = _parseTime(seance['heureFin']);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Modifier la séance'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titreCtrl,
                    decoration: oleaInput('Titre', Icons.title),
                  ),

                  const SizedBox(height: 12),

                  // Date Picker personnalisé
                  InkWell(
                    onTap: () async {
                      // Utilise une plage plus réaliste pour éviter le ralentissement
                      final now = DateTime.now();
                      final first = dateDebut ?? now.subtract(const Duration(days: 30));
                      final last = dateFin ?? now.add(const Duration(days: 90));
                      final initial = selectedDate ?? first;

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial.isBefore(first) || initial.isAfter(last) ? first : initial,
                        firstDate: first,
                        lastDate: last,
                        builder: (context, child) {
                          // Laisse ce bloc vide si pas besoin de thème personnalisé
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: oleaPrimaryReddishOrange,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        if (picked.isBefore(first) || picked.isAfter(last)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Date en dehors de la période de formation.')),
                          );
                        } else {
                          setState(() => selectedDate = picked);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: oleaLightBeige.withOpacity(.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: oleaSecondaryBrown, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: oleaPrimaryReddishOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDate != null
                                  ? 'Date : ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                                  : 'Sélectionner une date',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  // Heure Début Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedStartTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => selectedStartTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: oleaLightBeige.withOpacity(.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: oleaSecondaryBrown, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: oleaPrimaryReddishOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedStartTime != null
                                  ? 'Heure début : ${selectedStartTime!.format(context)}'
                                  : 'Sélectionner l\'heure de début',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Heure Fin Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedEndTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => selectedEndTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: oleaLightBeige.withOpacity(.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: oleaSecondaryBrown, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: oleaPrimaryReddishOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedEndTime != null
                                  ? 'Heure fin : ${selectedEndTime!.format(context)}'
                                  : 'Sélectionner l\'heure de fin',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Validation avant enregistrement
                  if (selectedDate == null || selectedStartTime == null || selectedEndTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs.')),
                    );
                    return;
                  }

                  final startMinutes = selectedStartTime!.hour * 60 + selectedStartTime!.minute;
                  final endMinutes = selectedEndTime!.hour * 60 + selectedEndTime!.minute;
                  if (startMinutes >= endMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Heure de début doit être avant l\'heure de fin.')),
                    );
                    return;
                  }

                  setState(() {
                    calendrier[index] = {
                      'titre': titreCtrl.text,
                      'date': Timestamp.fromDate(selectedDate!),
                      'heureDebut': selectedStartTime!.format(context),
                      'heureFin': selectedEndTime!.format(context),
                    };
                  });
                  Navigator.of(ctx).pop();
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

// Fonction utilitaire pour parser une chaîne "HH:mm" vers TimeOfDay
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildCalendrierList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: calendrier.asMap().entries.map((entry) {
        final index = entry.key;
        final seance = entry.value;
        final date = (seance['date'] as Timestamp).toDate();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: oleaLightBeige.withOpacity(.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: oleaSecondaryBrown, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            title: Text(
              seance['titre'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(date)} | ${seance['heureDebut']} - ${seance['heureFin']}',
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: oleaPrimaryReddishOrange),
              onPressed: () => _editSeanceDialog(index),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Formation'),
        backgroundColor: const Color(0xFF666666),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: titreCtrl,decoration: oleaInput('Titre', Icons.title),
            ),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration:  oleaInput('Description', Icons.description)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateDebut,
              child: InputDecorator(
                decoration: oleaInput('Date début', Icons.calendar_today),
                child: Text(
                  dateDebut != null
                      ? DateFormat('dd/MM/yyyy').format(dateDebut!)
                      : 'Sélectionner une date',
                ),
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: _selectDateFin,
              child: InputDecorator(
                decoration: oleaInput('Date fin', Icons.calendar_month),
                child: Text(
                  dateFin != null
                      ? DateFormat('dd/MM/yyyy').format(dateFin!)
                      : 'Sélectionner une date',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatutColor(calculerStatutFormation(dateDebut, dateFin)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      calculerStatutFormation(dateDebut, dateFin),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),


            DropdownButtonFormField<String>(
              value: modalite,
              items: ['Présentiel', 'En ligne'].map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (val) => setState(() => modalite = val!),
              decoration: commonDropdownDecoration(
                label: 'Modalité',
                icon: Icons.computer,
              ),
            ),
            const SizedBox(height: 12),
            OrganismeDropdown(
              value: organismeNom,

              selected: _selectedOrganisme,
              onChanged: (organisme) {
                setState(() {
                  _selectedOrganisme = organisme;
                });
              },
              decoration: commonDropdownDecoration(
                label: 'Organisme',
                icon: Icons.apartment_rounded,
              ),
            ),
            const SizedBox(height: 20),
            const Text('🗓️ Séances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildCalendrierList(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: DepartmentUserTable(
                initialSelection: _selectedParticipants,
                onChanged: (Map<String, Set<MyUser>> selection) {
                  setState(() {
                    _selectedParticipants = selection;
                  });
                },
              ),
            ),

            const SizedBox(height: 8),


    const SizedBox(height: 20),

            const SizedBox(height: 20),





            Center(
              child: ElevatedButton(
                onPressed: updateFormation,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB7482B)),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
