import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/organisme.dart';
import '../../../models/user.dart';
import '../../../services/auth.dart';
import '../../../widgets/custom_department_dropdown.dart';
import '../../../widgets/modalités.dart';
import '../../../widgets/organismes.dart';

class FormationsListPage extends StatefulWidget {
  const FormationsListPage({super.key});

  @override
  FormationsListPageState createState() => FormationsListPageState();
}

class FormationsListPageState extends State<FormationsListPage> {
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
  void dispose() {
    super.dispose();
  }

  InputDecoration commonDropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      prefixIcon: Icon(icon, color: oleaPrimaryReddishOrange),
      filled: true,
      fillColor: oleaLightBeige.withOpacity(.35),
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
  }

  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaSecondaryBrown = const Color(0xFF936037);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);
  InputDecoration oleaInput(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600, // label en gras
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

  final notifRef = FirebaseFirestore.instance.collection('notifications');
  OrganismeFormation? _selectedOrganisme;

  DateTime? selectedDateDebut;
  DateTime? selectedDateFin;
  String? dateError;
  String calculerStatutFormation(Timestamp dateDebut, Timestamp dateFin) {
    final now = DateTime.now();

    final debut = dateDebut.toDate();
    final fin = dateFin.toDate();

    if (now.isBefore(debut)) return "Planifiée";
    if (now.isAfter(fin)) return "Terminée";
    return "En cours";
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_currentAdmin == null) {
      return const Scaffold(
        body: Center(child: Text("Impossible de récupérer le profil admin.")),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('formations').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Erreur lors du chargement des formations.'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune formation disponible.'));
        }

        final formations = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).where((formation) =>
        formation['statut'] == 'Planifiée' || formation['statut'] == 'En Cours'
        ).toList();

        if (formations.isEmpty) {
          return const Center(child: Text('Aucune formation planifiée ou en cours.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formations en cours ou planifiées',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: oleaPrimaryDarkGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: formations.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final formation = formations[index];
                      return _buildFormationCard(formation, isSmallScreen);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormationCard(
    Map<String, dynamic> formation,
    bool isSmallScreen,
  ) {
    Color _getStatusColor(String statut) {
      switch (statut.toLowerCase()) {
        case 'terminée':
          return Colors.green;
        case 'annulée':
          return Colors.red;
        case 'en cours':
          return oleaPrimaryOrange;
        case 'planifiée':
          return oleaPrimaryReddishOrange;
        default:
          return oleaPrimaryDarkGray;
      }
    }

    // ✅ Nouveau : calcul dynamique du statut
    final Timestamp? dateDebut = formation['dateDebut'];
    final Timestamp? dateFin = formation['dateFin'];
    final statut = calculerStatutFormation(dateDebut!, dateFin!);
    final statusColor = _getStatusColor(statut);

    final Timestamp? dateDebutTs = formation['dateDebut'];
    final String dateDebutStr = dateDebutTs != null
        ? DateFormat('dd-MM-yyyy').format(dateDebutTs.toDate())
        : 'Inconnue';

    final Timestamp? dateFinTs = formation['dateFin'];
    final String dateFinStr = dateFinTs != null
        ? DateFormat('dd-MM-yyyy').format(dateFinTs.toDate())
        : 'Inconnue';

    return Card(
      color: oleaLightBeige.withOpacity(0.15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne titre
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: oleaPrimaryReddishOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formation['titre'] ?? 'Titre inconnu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: oleaPrimaryDarkGray,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: oleaSecondaryDarkBrown,
                  ),
                  tooltip: 'Modifier',
                  onPressed: () =>
                      _openEditSheet(context, formation['id'], formation),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: oleaPrimaryReddishOrange,
                  ),
                  tooltip: 'Supprimer',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Supprimer la formation'),
                        content: const Text(
                          'Voulez-vous vraiment supprimer cette formation ? Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Supprimer',
                              style: TextStyle(color: oleaPrimaryReddishOrange),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await deleteFormation(formation['id'], context);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statut,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 16, color: oleaSecondaryBrown),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formation['description'] ?? 'Pas de description.',
                    style: TextStyle(fontSize: 14, color: oleaPrimaryDarkGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Durée
            Row(
              children: [
                Icon(Icons.timelapse, size: 16, color: oleaSecondaryDarkBrown),
                const SizedBox(width: 4),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: oleaPrimaryDarkGray,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: 'Durée de la formation : '),
                        TextSpan(text: formation['duré'] ?? 'Inconnue'),
                        const TextSpan(text: ' Heures'),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Organisme
            Row(
              children: [
                Icon(Icons.domain, size: 16, color: oleaSecondaryDarkBrown),
                const SizedBox(width: 4),
                Text(
                  'Organisme : ',
                  style: TextStyle(
                    color: oleaPrimaryDarkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    formation['organismenom'] ?? 'Inconnue',
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Modalité
            Row(
              children: [
                Icon(Icons.style, size: 16, color: oleaSecondaryDarkBrown),
                const SizedBox(width: 4),
                Text(
                  'Modalité : ',
                  style: TextStyle(
                    color: oleaPrimaryDarkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    formation['modalite'] ?? 'Inconnue',
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: oleaSecondaryDarkBrown,
                ),
                const SizedBox(width: 4),
                Text(
                  'Début : ',
                  style: TextStyle(
                    color: oleaPrimaryDarkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    dateDebutStr,
                    style: TextStyle(color: oleaPrimaryDarkGray),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.event, size: 16, color: oleaSecondaryDarkBrown),
                const SizedBox(width: 4),
                Text(
                  'Fin : ',
                  style: TextStyle(
                    color: oleaPrimaryDarkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    dateFinStr,
                    style: TextStyle(color: oleaPrimaryDarkGray),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Boutons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  icon: Icon(
                    Icons.calendar_today,
                    color: oleaSecondaryDarkBrown,
                  ),
                  label: Text(
                    'Voir les séances',
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),
                  onPressed: () => _showSeancesDialog(context, formation),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.group, color: oleaSecondaryDarkBrown),
                  label: Text(
                    'Voir les participants',
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),
                  onPressed: () =>
                      _showParticipantsDialog(context, formation['id']),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.edit, color: oleaSecondaryDarkBrown),
                  label: Text(
                    'Participants',
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),

                  onPressed: () {
                    debugPrint('🟢 Bouton cliqué');
                    _editParticipantsDialog(context, formation);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions à implémenter dans ta classe si ce n’est pas encore fait :
  // logiques pour ouvrir le formulaire de modification
  void _openEditSheet(BuildContext ctx, String id, Map<String, dynamic> data) {
    DateTime? selectedDateDebut;
    DateTime? selectedDateFin;
    String? dateError;

    final dateDebutTs = data['dateDebut'] as Timestamp?;
    final dateFinTs = data['dateFin'] as Timestamp?;
    selectedDateDebut = dateDebutTs?.toDate();
    selectedDateFin = dateFinTs?.toDate();

    final titreCtrl = TextEditingController(text: data['titre']);
    final descCtrl = TextEditingController(text: data['description']);
    final departCtrl = TextEditingController(text: data['departement']);
    final dateDebutCTRL = TextEditingController(
      text: selectedDateDebut != null
          ? DateFormat('dd-MM-yyyy').format(selectedDateDebut)
          : '',
    );
    final dateFinCTRL = TextEditingController(
      text: selectedDateFin != null
          ? DateFormat('dd-MM-yyyy').format(selectedDateFin)
          : '',
    );
    final dureCtrl = TextEditingController(text: data['duré']);

    String? selectedModalite = data['modalite'];
    String selectedStatut = data['statut'] ?? '';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final _formKey = GlobalKey<FormState>();

              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modifier la formation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB7482B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: titreCtrl,
                        decoration: oleaInput('Titre', Icons.title),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Veuillez entrer un titre'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descCtrl,
                        decoration: oleaInput('Descritpion', Icons.description),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // 📅 Date début
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDateDebut ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDateDebut = picked;
                              dateDebutCTRL.text = DateFormat(
                                'dd-MM-yyyy',
                              ).format(picked);
                              if (selectedDateFin != null &&
                                  selectedDateFin!.isBefore(picked)) {
                                dateError =
                                    "La date de fin doit être postérieure à la date de début.";
                              } else {
                                dateError = null;
                              }
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: dateDebutCTRL,
                            decoration: oleaInput(
                              'Date début (dd-MM-yyyy)',
                              Icons.calendar_today,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Date début requise'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 📅 Date fin
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDateFin ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDateFin = picked;
                              dateFinCTRL.text = DateFormat(
                                'dd-MM-yyyy',
                              ).format(picked);
                              if (selectedDateDebut != null &&
                                  picked.isBefore(selectedDateDebut!)) {
                                dateError =
                                    "La date de fin doit être postérieure à la date de début.";
                              } else {
                                dateError = null;
                              }
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: dateFinCTRL,
                            decoration: oleaInput(
                              'Date fin (dd-MM-yyyy)',
                              Icons.calendar_today,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Date fin requise'
                                : null,
                          ),
                        ),
                      ),

                      if (dateError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dateError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: dureCtrl,
                        decoration: oleaInput('Durée', Icons.timelapse),
                      ),
                      const SizedBox(height: 16),

                      DropdownModalite(
                        selectedValue: selectedModalite,
                        onChanged: (val) =>
                            setModalState(() => selectedModalite = val),
                        decoration: commonDropdownDecoration(
                          label: 'Modalité',
                          icon: Icons.computer,
                        ),
                      ),
                      const SizedBox(height: 16),

                      OrganismeDropdown(
                        selected: _selectedOrganisme,
                        onChanged: (organisme) {
                          setState(() {
                            _selectedOrganisme = organisme;
                          });
                        },
                        decoration: commonDropdownDecoration(
                          label: 'Organisme',
                          icon: Icons.apartment_rounded,
                        ), value: _selectedOrganisme!.nom,
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('statuts')
                            .orderBy('label')
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData)
                            return const CircularProgressIndicator();
                          final statuts = snap.data!.docs
                              .map((d) => d['label'] as String)
                              .toList();

                          if (!statuts.contains(selectedStatut) &&
                              statuts.isNotEmpty) {
                            selectedStatut = statuts.first;
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedStatut,
                            decoration: commonDropdownDecoration(
                              label: 'Statut',
                              icon: Icons.verified_user,
                            ),
                            items: statuts.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => selectedStatut = val!),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            label: const Text(
                              'Annuler',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF8AF3C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Enregistrer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final adminName = _currentAdmin!.username;
                                final adminUid = _currentAdmin!.uid;
                                await FirebaseFirestore.instance
                                    .collection('formations')
                                    .doc(id)
                                    .update({
                                      'titre': titreCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'departement': departCtrl.text.trim(),
                                      'dateDebut': selectedDateDebut != null
                                          ? Timestamp.fromDate(
                                              selectedDateDebut!,
                                            )
                                          : null,
                                      'dateFin': selectedDateFin != null
                                          ? Timestamp.fromDate(selectedDateFin!)
                                          : null,
                                      'duré': dureCtrl.text.trim(),
                                      'modalite': selectedModalite ?? '',
                                      'organismeId': _selectedOrganisme?.id,
                                      'organismenom': _selectedOrganisme?.nom,
                                      'statut': selectedStatut,
                                      'createdByUid': adminUid,
                                      'createdByName': adminName,
                                    });
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSeancesDialog(
    BuildContext context,
    Map<String, dynamic> formation,
  ) {
    final dateDebut = (formation['dateDebut'] as Timestamp?)?.toDate();
    final dateFin = (formation['dateFin'] as Timestamp?)?.toDate();
    if (dateDebut == null || dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Impossible de gérer les séances sans dates de début et de fin.",
          ),
        ),
      );
      return;
    }

    // On récupère la liste des séances depuis la formation
    List<Map<String, dynamic>> calendrier = List<Map<String, dynamic>>.from(
      formation['calendrier'] ?? [],
    );

    // On affiche une boîte de dialogue (popup)
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.event_note, color: oleaPrimaryReddishOrange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Séances',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF432918), // oleaSecondaryDarkBrown
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),

            // Contenu principal
            content: calendrier.isEmpty
                ? const Text('Aucune séance programmée.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: calendrier.length,
                      itemBuilder: (context, index) {
                        final seance = calendrier[index];

                        // 🔒 Sécuriser l'extraction des données
                        final date = (seance['date'] is Timestamp)
                            ? (seance['date'] as Timestamp).toDate()
                            : (seance['date'] as DateTime? ?? DateTime.now());

                        final heureDebut =
                            seance['heureDebut']?.toString() ?? 'Inconnue';
                        final heureFin =
                            seance['heureFin']?.toString() ?? 'Inconnue';
                        final titre =
                            seance['titre']?.toString() ?? 'Sans titre';
                        final statut =
                            seance['statut']?.toString() ?? 'Non défini';

                        return Card(
                          color: oleaLightBeige.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: oleaSecondaryBrown.withOpacity(0.5),
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.schedule,
                                    color: oleaSecondaryDarkBrown,
                                  ),
                                  title: Text(
                                    titre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: oleaSecondaryDarkBrown,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_formatDate(date)}   |   $heureDebut → $heureFin',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: oleaPrimaryDarkGray,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Statut : $statut',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _getStatutColor(statut),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: oleaPrimaryOrange,
                                    ),
                                    onPressed: () async {
                                      final updatedSeance =
                                          await _editSeanceDialog(
                                            context,
                                            seance,
                                            dateDebut,
                                            dateFin,
                                          );
                                      if (updatedSeance != null) {
                                        setState(() {
                                          calendrier[index] = updatedSeance;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  color: oleaPrimaryReddishOrange,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: oleaLightBeige
                                            .withOpacity(0.9),
                                        title: Text(
                                          'Confirmer la suppression',
                                          style: TextStyle(
                                            color: oleaSecondaryDarkBrown,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        content: Text(
                                          'Voulez-vous vraiment supprimer cette séance ?',
                                          style: TextStyle(
                                            color: oleaPrimaryDarkGray,
                                            fontSize: 16,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Annuler',
                                              style: TextStyle(
                                                color: oleaPrimaryReddishOrange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Supprimer',
                                              style: TextStyle(
                                                color: oleaPrimaryReddishOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      setState(() {
                                        calendrier.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Séance supprimée',
                                          ),
                                          backgroundColor:
                                              oleaPrimaryReddishOrange
                                                  .withOpacity(0.8),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

            // Actions en bas de la modale
            actions: [
              Wrap(
                spacing: 8, // espace horizontal entre les boutons
                runSpacing: 4, // espace vertical si retour à la ligne
                alignment: WrapAlignment
                    .end, // aligne à droite (comme le fait AlertDialog)
                children: [
                  /*
                  TextButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  */
                  TextButton(
                    child: Text(
                      'Ajouter',
                      style: TextStyle(color: oleaPrimaryReddishOrange),
                    ),
                    onPressed: () async {
                      final nouvelleSeance = await _editSeanceDialog(
                        context,
                        null,
                        dateDebut,
                        dateFin,
                      );
                      if (nouvelleSeance != null) {
                        setState(() {
                          calendrier.add(nouvelleSeance);
                        });
                      }
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Enregistrer',
                      style: TextStyle(color: oleaSecondaryDarkBrown),
                    ),
                    onPressed: () async {
                      final calendrierFirestore = calendrier
                          .map(
                            (s) => {
                              'date': s['date'],
                              'heureDebut': s['heureDebut'],
                              'heureFin': s['heureFin'],
                              'titre': s['titre'],
                              'statut': s['statut'],
                            },
                          )
                          .toList();

                      await FirebaseFirestore.instance
                          .collection('formations')
                          .doc(formation['id'])
                          .update({'calendrier': calendrierFirestore});

                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showParticipantsDialog(BuildContext ctx, String formationId) async {
    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: oleaLightBeige.withOpacity(0.9),
          title: Row(
            children: [
              Icon(Icons.group, color: oleaPrimaryReddishOrange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Participants',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF432918),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('participations')
                .where('formationId', isEqualTo: formationId)
                .get(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: oleaPrimaryReddishOrange,
                    ),
                  ),
                );
              }

              // --- Regrouper par département ---
              final docs = snap.data!.docs;
              final Map<String, List<Map<String, dynamic>>> parDept = {};
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final dept = d['department'] ?? 'Autre';
                parDept.putIfAbsent(dept, () => []).add(d);
              }

              // --- Icônes par département ---
              const Map<String, IconData> iconsParDept = {
                'IT': Icons.computer,
                'Santé': Icons.local_hospital,
                'Automobile': Icons.directions_car,
                'Voyages': Icons.flight_takeoff,
                'IRDS': Icons.security,
                'Finance': Icons.attach_money,
                'Comptabilité': Icons.business,
              };

              return SizedBox(
                width: 350,
                child: ListView(
                  shrinkWrap: true,
                  children: parDept.entries.map((entry) {
                    final dept = entry.key;
                    final list = entry.value;

                    // séparer acceptés / refusés
                    final refuses = list.where((p) => p['status'] == 'refused');
                    final invites = list.where(
                      (p) =>
                          p['status'] == 'invited'
                    );

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('department', isEqualTo: dept)
                          .where('role', isEqualTo: 'user')
                          .get(),
                      builder: (context, usersSnap) {
                        if (!usersSnap.hasData) return const SizedBox();

                        final totalUsers = usersSnap.data!.docs
                            .map((d) => d['username'].toString())
                            .toSet();

                        // On récupère les noms invités pour ce département
                        final invitedNames = invites
                            .where((p) => p['department'] == dept)
                            .map((p) => p['userName'].toString())
                            .toSet();
                        if (invitedNames.isEmpty) return const SizedBox();

                        final icon = iconsParDept[dept] ?? Icons.apartment;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Tooltip(
                                message: dept,
                                child: Icon(
                                  icon,
                                  size: 20,
                                  color: oleaPrimaryReddishOrange.withOpacity(
                                    0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$dept : ${invitedNames.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: oleaPrimaryDarkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(
                'Fermer',
                style: TextStyle(
                  color: oleaPrimaryReddishOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteFormation(String formationId, BuildContext context) async {
    try {
      // Supprime la formation
      await FirebaseFirestore.instance
          .collection('formations')
          .doc(formationId)
          .delete();

      // Supprime les participations liées
      final participations = await FirebaseFirestore.instance
          .collection('participations')
          .where('formationId', isEqualTo: formationId)
          .get();

      for (var doc in participations.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formation supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<Map<String, dynamic>?> _editSeanceDialog(
    BuildContext context,
    Map<String, dynamic>? seance,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    final titreCtrl = TextEditingController(text: seance?['titre'] ?? '');

    DateTime? selectedDate = (seance?['date'] as Timestamp?)?.toDate();
    TimeOfDay? startTime = _parseTimeOfDay(seance?['heureDebut']);
    TimeOfDay? endTime = _parseTimeOfDay(seance?['heureFin']);

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: oleaLightBeige.withOpacity(0.9),
          title: Row(
            children: [
              Icon(
                seance == null ? Icons.add : Icons.edit,
                color: oleaPrimaryReddishOrange,
              ),
              const SizedBox(width: 8),
              Text(
                seance == null ? 'Nouvelle séance' : 'Modifier la séance',
                style: TextStyle(
                  color: oleaSecondaryDarkBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreCtrl,
                  decoration: oleaInput('Titre', Icons.title),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: oleaPrimaryReddishOrange,
                  ),
                  title: Text(
                    selectedDate == null
                        ? 'Choisir une date'
                        : _formatDate(selectedDate!),
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: seance?['date'] != null
                          ? (seance!['date'] as Timestamp?)?.toDate() ??
                                dateDebut
                          : dateDebut,
                      firstDate: dateDebut,
                      lastDate: dateFin,
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.schedule,
                    color: oleaPrimaryReddishOrange,
                  ),
                  title: Text(
                    startTime == null
                        ? 'Heure de début'
                        : _formatTimeOfDay(startTime!),
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.schedule_outlined,
                    color: oleaPrimaryReddishOrange,
                  ),
                  title: Text(
                    endTime == null
                        ? 'Heure de fin'
                        : _formatTimeOfDay(endTime!),
                    style: TextStyle(color: oleaPrimaryDarkGray),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => endTime = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: oleaPrimaryReddishOrange),
              ),
              onPressed: () => Navigator.pop(context, null),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(seance == null ? 'Ajouter' : 'Modifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: oleaPrimaryReddishOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (titreCtrl.text.trim().isEmpty ||
                    selectedDate == null ||
                    startTime == null ||
                    endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tous les champs sont obligatoires.'),
                    ),
                  );
                  return;
                }

                final startDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  startTime!.hour,
                  startTime!.minute,
                );
                final endDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  endTime!.hour,
                  endTime!.minute,
                );
                if (endDateTime.isBefore(startDateTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Heure de fin < heure de début.'),
                    ),
                  );
                  return;
                }

                final statut = _calculerStatut(
                  selectedDate!,
                  startTime!,
                  endTime!,
                );

                Navigator.pop(context, {
                  'titre': titreCtrl.text.trim(),
                  'date': Timestamp.fromDate(selectedDate!),
                  'heureDebut': _formatTimeOfDay(startTime!),
                  'heureFin': _formatTimeOfDay(endTime!),
                  'statut': statut,
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers ──────────────────────────────────────────────────────────────────────

  /// Convertit un String "HH:mm" en TimeOfDay.
  /// Retourne null si la chaîne est mal formée.
  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Formatte TimeOfDay en "HH:mm" (toujours deux chiffres).
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  /// Ex. 01/07/2025  (tu l’as sans doute déjà)
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'Planifiée':
        return Colors.blue;
      case 'En Cours':
        return Colors.orange;
      case 'Terminée':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /*-----------------------------------*/
  String _calculerStatut(
    DateTime date,
    TimeOfDay heureDebut,
    TimeOfDay heureFin,
  ) {
    final now = DateTime.now();
    final debut = DateTime(
      date.year,
      date.month,
      date.day,
      heureDebut.hour,
      heureDebut.minute,
    );
    final fin = DateTime(
      date.year,
      date.month,
      date.day,
      heureFin.hour,
      heureFin.minute,
    );

    if (now.isBefore(debut)) return 'Planifiée';
    if (now.isAfter(fin)) return 'Terminée';
    return 'En cours';
  }

  /*-------------------------
*/
  Future<void> _editParticipantsDialog(
      BuildContext context,
      Map<String, dynamic> formation,
      ) async {
    // --- 1. Retrieve initial participants as MyUser objects ---
    final List<dynamic> initialParticipantsData = formation['participants'] ?? [];
    Map<String, Set<MyUser>> initialSelection = {};

    for (var pData in initialParticipantsData) {
      final MyUser user = MyUser(
        uid: pData['uid'] ?? '',
        username: pData['username'] ?? '',
        department: pData['department'] ?? '',
        email: pData['email'] ?? '',
        poste: pData['poste'] ?? '',
        role: pData['role'] ?? '',
        photoUrl: pData['photoUrl'] ?? '',
        joinDate: (pData['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        emailVerified: pData['emailVerified'] as bool? ?? false,
      );
      initialSelection.putIfAbsent(user.department, () => {}).add(user);
    }

    // Create a mutable copy for the dialog's local state
    Map<String, Set<MyUser>> updatedSelection = Map.from(initialSelection);

    // --- 2. Show the participant selection dialog ---
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Gérer les participants',
          style: TextStyle(
            color: Color(0xFF432918), // oleaSecondaryDarkBrown
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // Make it responsive
          height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
          child: DepartmentUserTable(
            initialSelection: updatedSelection, // Pass the mutable copy
            onChanged: (selection) {
              // Update the local copy when selection changes in the table
              updatedSelection = selection;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Annuler',
              style: TextStyle(
                color: Color(0xFFB7482B), // oleaPrimaryReddishOrange
              ),
            ),
            onPressed: () => Navigator.pop(context, false), // User cancelled
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: oleaPrimaryReddishOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Enregistrer'),
            onPressed: () => Navigator.pop(context, true), // User confirmed
          ),
        ],
      ),
    );

    if (confirmed != true) return; // User cancelled the dialog

    // --- 3. Prepare for Firestore batch write operations ---
    final batch = FirebaseFirestore.instance.batch();
    final formationRef = FirebaseFirestore.instance.collection('formations').doc(formation['id']);

    // Flatten initial and updated selections into sets of MyUser for easier comparison
    Set<MyUser> initialUsersSet = initialSelection.values.expand((s) => s).toSet();
    Set<MyUser> updatedUsersSet = updatedSelection.values.expand((s) => s).toSet();

    // Find users to remove (present initially but not in updated)
    Set<MyUser> usersToRemove = initialUsersSet.difference(updatedUsersSet);
    // Find users to add (present in updated but not initially)
    Set<MyUser> usersToAdd = updatedUsersSet.difference(initialUsersSet);

    // --- 4. Process removals (delete participations, notifications, update formation's participants array) ---
    for (final user in usersToRemove) {
      // a) Find and delete the participation document for this user
      final participationQuery = await FirebaseFirestore.instance
          .collection('participations')
          .where('formationId', isEqualTo: formation['id'])
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (participationQuery.docs.isNotEmpty) {
        batch.delete(participationQuery.docs.first.reference);
      }

      // b) Delete associated notifications for this user and formation
      final notificationQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverUid', isEqualTo: user.uid)
          .where('formationId', isEqualTo: formation['id'])
          .get();

      for (final notifDoc in notificationQuery.docs) {
        batch.delete(notifDoc.reference);
      }

      // c) Remove this user from the 'participants' array in the formation document
      batch.update(formationRef, {
        'participants': FieldValue.arrayRemove([
          {
            'uid': user.uid,
            'username': user.username,
            'department': user.department,
            'email': user.email,
            'poste': user.poste,
            'role': user.role,
            'photoUrl': user.photoUrl,
            'joinDate': Timestamp.fromDate(user.joinDate),
            'emailVerified': user.emailVerified,
          }
        ]),
      });
    }

    // --- 5. Process additions (add participations, notifications, update formation's participants array) ---
    for (final user in usersToAdd) {
      // a) Add a new participation document
      final partRef = FirebaseFirestore.instance.collection('participations').doc();
      batch.set(partRef, {
        'formationId': formation['id'],
        'formationtitle': formation['titre'],
        'department': user.department,
        'userName': user.username,
        'userId': user.uid,
        'status': 'invited',
        'organismeId': formation['organismeId'], // Assuming these are still relevant from the formation
        'organismenom': formation['organismenom'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // b) Add this user to the 'participants' array in the formation document
      batch.update(formationRef, {
        'participants': FieldValue.arrayUnion([
          {
            'uid': user.uid,
            'username': user.username,
            'department': user.department,
            'email': user.email,
            'poste': user.poste,
            'role': user.role,
            'photoUrl': user.photoUrl,
            'joinDate': Timestamp.fromDate(user.joinDate),
            'emailVerified': user.emailVerified,
          }
        ]),
      });

      // c) Create a new invitation notification for this user
      final adminUid = _currentAdmin!.uid;
      final adminName = _currentAdmin!.username;

      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverUid': user.uid,
        'UserReceiver': user.username,
        'Useremail': user.email,
        'AdminSenderUid': adminUid,
        'AdminSenderName': adminName,
        'formationtitle': formation['titre'],
        'title': 'Nouvelle invitation',
        'body': 'Vous avez été invité à la formation "${formation['titre']}"',
        'formationId': formation['id'],
        'seen': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // --- 6. Commit the batch write operations ---
    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participants mis à jour avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour des participants: $e')),
      );
    }
  }
}
