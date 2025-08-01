import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firstproject/services/auth.dart';

import '../../../models/user.dart';
import '../../../widgets/custom_department_dropdown.dart';
import '../../../widgets/modalités.dart';
import '../../../widgets/organismes.dart';
import 'package:firstproject/models/organisme.dart';

class Addformation extends StatefulWidget {
  const Addformation({super.key});


  @override
  _AddformationState createState() => _AddformationState();
}

class _AddformationState extends State<Addformation> {
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




  DateTime? _dateFin;
  DateTime? _dateDebut;
  Map<String, Set<MyUser>> _selectedUsers = {};
  List<Map<String, dynamic>> _calendrier = [];
  final notifRef = FirebaseFirestore.instance.collection('notifications');

  // Controllers pour le formulaire d'ajout
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  final _dureController = TextEditingController();
  String? _selectedModalite;
  OrganismeFormation? _selectedOrganisme;

  // 1. Palette OLEA
  Color oleaPrimaryReddishOrange = Color(0xFFB7482B);
  Color oleaPrimaryOrange        = Color(0xFFF8AF3C);
  Color oleaSecondaryBrown       = Color(0xFF936037);
  Color oleaPrimaryDarkGray      = Color(0xFF666666);
  Color oleaLightBeige           = Color(0xFFE3D9C0);
  // 2. Exemple d’InputDecoration “OLEA”
  InputDecoration oleaInput(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600,           // label en gras
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
          const SnackBar(content: Text('Choisis_dateDebutsez une modalité')),
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

      // Check if _selectedUsers contains any actual MyUser objects
      if (_selectedUsers.values.every((set) => set.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez au moins un participant')),
        );
        return;
      }

      // Convert Set<MyUser> to List<Map<String, dynamic>> for Firestore
      final List<Map<String, dynamic>> participants = _selectedUsers.entries
          .expand(
            (entry) => entry.value.map(
              (user) => {
            'uid': user.uid, // Store UID
            'username': user.username,
            'department': user.department,
            'email': user.email,
            'poste': user.poste,
            'role': user.role,
            'photoUrl': user.photoUrl,
            'joinDate': Timestamp.fromDate(user.joinDate),
            'emailVerified': user.emailVerified,
          },
        ),
      )
          .toList();

      final participantsCount = participants.length;

      try {
        final calendrierFirestore = _calendrier
            .map(
              (s) => {
            'titre': s['titre'],
            'date': Timestamp.fromDate(s['date']),
            'heureDebut': s['heureDebut'].format(context),
            'heureFin': s['heureFin'].format(context),
            'statut': s['statut'],
          },
        )
            .toList();
        // 3️⃣ Récupère l’UID de l’admin (créateur)
        final adminUid = _currentAdmin!.uid;
        final adminName = _currentAdmin!.username;


        final docRef = await FirebaseFirestore.instance
            .collection('formations')
            .add({
          'titre': _titreController.text.trim(),
          'description': _descriptionController.text.trim(),
          'statut': 'Planifiée',
          'createdAt': FieldValue.serverTimestamp(),
          'createdByUid': adminUid,
          'createdByName': adminName,
          'dateDebut': _dateDebut != null ? Timestamp.fromDate(_dateDebut!) : null,
          'dateFin': _dateFin != null ? Timestamp.fromDate(_dateFin!) : null,
          'duré': _dureController.text.trim(),
          'modalite': _selectedModalite ?? '',
          'organismeId': _selectedOrganisme?.id,
          'organismenom': _selectedOrganisme?.nom,
          'calendrier': calendrierFirestore,
          'participants': participants,
          'participantsCount': participantsCount,
        });

        final batch = FirebaseFirestore.instance.batch();

        for (final entry in _selectedUsers.entries) {
          final dept = entry.key;
          for (final user in entry.value) {
            // Use the MyUser object directly
            final partDoc = FirebaseFirestore.instance.collection('participations').doc();
            batch.set(partDoc, {
              'formationId': docRef.id,
              'formationtitle': _titreController.text.trim(),
              'userId': user.uid, // Use user.uid
              'userName': user.username, // Use user.username
              'department': dept,
              'status': 'invited',
              'organismeId': _selectedOrganisme?.id,
              'organismenom': _selectedOrganisme?.nom,
              'createdAt': FieldValue.serverTimestamp(),
            });

            await notifRef.add({
              'receiverUid': user.uid, // Use user.uid
              'UserReceiver': user.username, // Use user.username
              'Useremail': user.email, // Use user.email
              'AdminSenderUid': adminUid,
              'AdminSenderName': adminName, // prénom de l’admin
              'title': 'Nouvelle invitation',
              'body': 'Vous êtes invité à la formation "${_titreController.text.trim()}"',
              'timestamp': FieldValue.serverTimestamp(),
              'formationId': docRef.id,
              'seen': false,
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
          _calendrier.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }

    // Le formulaire complet, repris de ton _buildAddFormationPage()
    return SingleChildScrollView(
      padding: EdgeInsets.all(formPadding),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: EdgeInsets.all(formPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Titre
                  TextFormField(
                    controller: _titreController,
                    decoration: oleaInput('Titre de la formation', Icons.title),
                    validator: (v) => v==null||v.isEmpty ? 'Veuillez saisir un titre' : null,
                  ),
                  SizedBox(height: 12),

                  // Durée
                  TextFormField(
                    controller: _dureController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: oleaInput('Durée de la formation', Icons.timer),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez saisir une durée' : null,
                  ),
                  SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: oleaInput('Description', Icons.description),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez saisir une description' : null,
                  ),
                  SizedBox(height: 12),

                  // Modalité
                  StatefulBuilder(
                    builder: (context, setLocalState) {
                      return DropdownModalite(
                        selectedValue: _selectedModalite,
                        onChanged: (val) =>
                            setLocalState(() => _selectedModalite = val),
                        decoration: oleaInput('Modalité', Icons.computer),

                      );
                    },
                  ),
                  SizedBox(height: 12),

                  // Date de début
                  TextFormField(
                    controller: _dateDebutController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: oleaInput('Date de début', Icons.calendar_today).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => _selectDateDebut(context),
                      ),
                    ),
                    readOnly: true,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez sélectionner une date' : null,
                  ),
                  SizedBox(height: 12),

                  // Date de fin
                  TextFormField(
                    controller: _dateFinController,
                    style: TextStyle(fontSize: fieldFontSize),
                    decoration: oleaInput('Date de fin', Icons.calendar_today).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => _selectDateFin(context),
                      ),
                    ),
                    readOnly: true,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Veuillez sélectionner une date' : null,
                  ),
                  SizedBox(height: 12),



                  // Organisme
                  OrganismeDropdown(
                    selected: _selectedOrganisme,
                    onChanged: (organisme) {
                      setState(() {
                        _selectedOrganisme = organisme;
                      });
                    },
                    decoration: oleaInput('Organsime', Icons.apartment_rounded), value: '',

                  ),

                  SizedBox(height: 12),
                  // Bouton Ajouter séance
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.event_available,color: Colors.black),
                          label: const Text('Ajouter séance',),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: oleaPrimaryReddishOrange, // Use OLEA's primary orange
                            foregroundColor: Colors.black,
                            // Set text/icon color to white for contrast
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(fontSize: fieldFontSize),
                          ),
                          onPressed: _ouvrirPopupCalendrier,
                        ),                      ),
                    ],
                  ),

                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.visibility, color: Colors.black),
                          label: const Text('Afficher séances'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(fontSize: fieldFontSize),
                          ),
                          onPressed: _ouvrirPopupSeances,
                        ),
                      ),
                    ],
                  ),



                  // Participants par département
                  DepartmentUserTable(
                    onChanged: (Map<String, Set<MyUser>> map) {
                      setState(() {
                        _selectedUsers = map;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  // Bouton enregistrer
                  SizedBox(
                    width: double.infinity,
                    child:
                    ElevatedButton.icon(
                      onPressed: _ajouterFormation,
                      icon: Icon(Icons.save, size: isSmallScreen ? 18 : 24),
                      label: Text(
                        'Ajouter la Formation',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oleaPrimaryOrange, // Changed to OLEA's primary orange!
                        foregroundColor: Colors.white, // Keep text white for contrast
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
            )
        ),
      ),
    );
  }

  // Méthode à définir pour ouvrir la popup calendrier
  void _ouvrirPopupCalendrier() {
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez d'abord sélectionner une date de début et de fin pour la formation."),
        ),
      );
      return;
    }
    final DateTime dateDebutFormation = _dateDebut!;
    final DateTime dateFinFormation = _dateFin!;
    DateTime date = dateDebutFormation;
    TimeOfDay heureDebut = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay heureFin = const TimeOfDay(hour: 12, minute: 0);
    String titre = '';
    String statut = 'Planifiée';

    void _updateStatut(StateSetter setStateDialog) {
      final now = DateTime.now();
      final dateDebut = DateTime(
        date.year,
        date.month,
        date.day,
        heureDebut.hour,
        heureDebut.minute,
      );
      final dateFin = DateTime(
        date.year,
        date.month,
        date.day,
        heureFin.hour,
        heureFin.minute,
      );

      String newStatut;
      if (now.isBefore(dateDebut)) {
        newStatut = 'Planifiée';
      } else if (now.isAfter(dateFin)) {
        newStatut = 'Terminée';
      } else {
        newStatut = 'En cours';
      }

      setStateDialog(() {
        statut = newStatut;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> _pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: dateDebutFormation, // ✅ borne min
              lastDate: dateFinFormation,    // ✅ borne max
            );
            if (picked != null) {
              setStateDialog(() {
                date = picked;
                _updateStatut(setStateDialog);
              });
            }
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
                  if (heureFin.hour < picked.hour ||
                      (heureFin.hour == picked.hour && heureFin.minute <= picked.minute)) {
                    heureFin = picked.replacing(minute: picked.minute + 30);
                  }
                } else {
                  heureFin = picked;
                }
                _updateStatut(setStateDialog);
              });
            }
          }

          return AlertDialog(
            title: const Text('Nouvelle séance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(DateFormat('yyyy-MM-dd').format(date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: Text('Début : ${heureDebut.format(context)}'),
                  onTap: () => _pickTime(debut: true),
                ),
                ListTile(
                  leading: const Icon(Icons.stop),
                  title: Text('Fin    : ${heureFin.format(context)}'),
                  onTap: () => _pickTime(debut: false),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Titre / Salle (optionnel)',
                    ),
                    onChanged: (v) => titre = v,
                  ),
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

                  setState(() {
                    _calendrier.add({
                      'titre': titre,
                      'date': date,
                      'heureDebut': heureDebut,
                      'heureFin': heureFin,
                      'statut': statut,
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
    );
  }

  void _ouvrirPopupSeances() {
    if (_calendrier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune séance ajoutée pour le moment.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Séances ajoutées'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _calendrier.length,
                itemBuilder: (context, index) {
                  final seance = _calendrier[index];
                  final date = DateFormat('dd/MM/yyyy').format(seance['date']);
                  final heureDebut = seance['heureDebut'].format(context);
                  final heureFin = seance['heureFin'].format(context);
                  final titre = seance['titre'] ?? '';
                  final statut = seance['statut'] ?? '';

                  return Card(
                    color: const Color(0xFFFFF4E0), // fond léger orange
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.event_note, color: Color(0xFFB7482B)),
                      title: Text('Le $date de $heureDebut à $heureFin',
                          style: const TextStyle(color: Color(0xFF666666))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (titre.isNotEmpty)
                            Text("Salle : $titre", style: const TextStyle(color: Color(0xFF666666))),
                          Text("Statut : $statut", style: const TextStyle(color: Color(0xFF666666))),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFB7482B)),
                        onPressed: () {
                          setState(() {
                            _calendrier.removeAt(index);
                          });
                          setStateDialog(() {}); // met à jour l'UI de la modale
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer', style: TextStyle(color: Color(0xFFB7482B))),
              ),
            ],
          );
        },
      ),
    );
  }

}
