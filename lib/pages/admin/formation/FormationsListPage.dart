import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../widgets/modalités.dart';

class FormationsListPage extends StatefulWidget {
  const FormationsListPage({super.key});

  @override
  FormationsListPageState createState() => FormationsListPageState();
}

class FormationsListPageState extends State<FormationsListPage> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toutes les Formations',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
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
          return Colors.orange;
        case 'planifiée':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    String statut = formation['statut'] ?? 'Planifiée';
    Color statusColor = _getStatusColor(statut);

    return Card(
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
                Icon(Icons.school, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formation['titre'] ?? 'Titre inconnu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  tooltip: 'Modifier',
                  onPressed: () =>
                      _openEditSheet(context, formation['id'], formation),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
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
                const Icon(Icons.description, size: 20, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formation['description'] ?? 'Pas de description.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Durée
            Row(
              children: [
                const Icon(Icons.timelapse, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Colors.black87,
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
                const Icon(Icons.domain, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Organisme : ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    formation['organismeNom'] ?? 'Inconnu',
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
                const Icon(Icons.style, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Modalité : ',
                  style: TextStyle(
                    color: Colors.black87,
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Début : ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    formation['dateDebut'] ?? 'Inconnue',
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Fin : ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    formation['dateFin'] ?? 'Inconnue',
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Boutons
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Voir les séances"),
                  onPressed: () => _showSeancesDialog(context, formation),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('Voir les participants'),
                  onPressed: () =>
                      _showParticipantsDialog(context, formation['id']),
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
    final titreCtrl = TextEditingController(text: data['titre']);
    final descCtrl = TextEditingController(text: data['description']);
    final departCtrl = TextEditingController(text: data['departement']);
    final dateDebutCTRL = TextEditingController(text: data['dateDebut']);
    final dateFinCTRL = TextEditingController(text: data['dateFin']);
    final dureCtrl = TextEditingController(text: data['duré']);

    String? selectedModalite = data['modalite'];
    String selectedStatut = data['statut'] ?? '';
    String selectedOrganisme = data['organismeNom'] ?? '';

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
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Modifier la formation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: titreCtrl,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: dateDebutCTRL,
                      decoration: const InputDecoration(
                        labelText: 'Date début (yyyy-MM-dd)',
                      ),
                    ),
                    TextField(
                      controller: dateFinCTRL,
                      decoration: const InputDecoration(
                        labelText: 'Date fin (yyyy-MM-dd)',
                      ),
                    ),
                    TextField(
                      controller: dureCtrl,
                      decoration: const InputDecoration(labelText: 'Durée'),
                    ),

                    const SizedBox(height: 12),

                    // Dropdown Modalité
                    DropdownModalite(
                      selectedValue: selectedModalite,
                      onChanged: (val) =>
                          setModalState(() => selectedModalite = val),
                    ),

                    const SizedBox(height: 12),

                    // Dropdown Organisme
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('organismesFormation')
                          .orderBy('nom')
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData)
                          return const CircularProgressIndicator();

                        final organismes = snap.data!.docs
                            .map((d) => d['nom'] as String)
                            .toList();

                        if (!organismes.contains(selectedOrganisme) &&
                            organismes.isNotEmpty) {
                          selectedOrganisme = organismes.first;
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedOrganisme,
                          decoration: const InputDecoration(
                            labelText: 'Organisme',
                          ),
                          items: organismes.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedOrganisme = val!),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Dropdown Statut
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
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                          ),
                          items: statuts.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedStatut = val!),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('formations')
                            .doc(id)
                            .update({
                              'titre': titreCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'departement': departCtrl.text.trim(),
                              'dateDebut': dateDebutCTRL.text.trim(),
                              'dateFin': dateFinCTRL.text.trim(),
                              'duré': dureCtrl.text.trim(),
                              'modalite': selectedModalite ?? '',
                              'organismeNom': selectedOrganisme,
                              'statut': selectedStatut,
                            });

                        Navigator.pop(ctx);
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ],
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
              children: const [
                Icon(Icons.event_note, color: Colors.blue),
                SizedBox(width: 8),
                Text('Séances programmées'),
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
                        final date = (seance['date'] as Timestamp).toDate();
                        final heureDebut = seance['heureDebut'] ?? '';
                        final heureFin = seance['heureFin'] ?? '';
                        final titre = seance['titre'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.schedule),
                            title: Text(
                              titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatDate(date)}   |   $heureDebut → $heureFin',
                              style: const TextStyle(fontSize: 13),
                            ),
                            // Boutons d'action (modifier / supprimer)
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final updatedSeance =
                                        await _editSeanceDialog(
                                          context,
                                          seance,
                                        );
                                    if (updatedSeance != null) {
                                      setState(() {
                                        calendrier[index] = updatedSeance;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      calendrier.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            // Actions en bas de la modale
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Ajouter une séance'),
                onPressed: () async {
                  final nouvelleSeance = await _editSeanceDialog(context, null);
                  if (nouvelleSeance != null) {
                    setState(() {
                      calendrier.add(nouvelleSeance);
                    });
                  }
                },
              ),
              TextButton(
                child: const Text('Enregistrer'),
                onPressed: () {
                  // Mettre à jour les données de la formation ici si nécessaire
                  formation['calendrier'] = calendrier;
                  Navigator.pop(context);
                },
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
          title: Row(
            children: const [
              Icon(Icons.group, color: Colors.blue),
              SizedBox(width: 8),
              Text('Participants par département'),
            ],
          ),
          content: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('participations')
                .where('formationId', isEqualTo: formationId)
                .get(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
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

              // --- Contenu de la popup ---
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
                          p['status'] == 'invited' || p['status'] == 'accepted',
                    );

                    // Récupère la liste complète d’utilisateurs du département
                    // (pour savoir s’ils sont tous invités)
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

                        final acceptedNames = invites
                            .map((p) => p['userName'].toString())
                            .toSet();

                        // Règle d’affichage
                        String content;
                        if (refuses.isEmpty &&
                            acceptedNames.containsAll(totalUsers)) {
                          content = 'tous';
                        } else {
                          content = acceptedNames.join(', ');
                        }

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
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$dept : $content',
                                  style: const TextStyle(fontSize: 13),
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
              child: const Text('Fermer'),
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
  ) async {
    // ─────────────────────────── Contrôleurs & valeurs initiales ────────────────────────────
    final titreCtrl = TextEditingController(text: seance?['titre'] ?? '');

    // Date
    DateTime? selectedDate = (seance?['date'] as Timestamp?)
        ?.toDate(); // null si ajout

    // Heures (converties depuis "HH:mm" s’il y en a)
    TimeOfDay? startTime = _parseTimeOfDay(seance?['heureDebut']);
    TimeOfDay? endTime = _parseTimeOfDay(seance?['heureFin']);

    // ────────────────────────────────────── UI ──────────────────────────────────────────────
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(seance == null ? Icons.add : Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              Text(seance == null ? 'Nouvelle séance' : 'Modifier la séance'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ──────────── Champ titre ────────────
                TextField(
                  controller: titreCtrl,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 12),

                // ──────────── Sélecteur de date ────────────
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate == null
                        ? 'Choisir une date'
                        : _formatDate(selectedDate!),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),

                // ──────────── Sélecteur heure début ────────────
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    startTime == null
                        ? 'Heure de début'
                        : _formatTimeOfDay(startTime!),
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

                // ──────────── Sélecteur heure fin ────────────
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    endTime == null
                        ? 'Heure de fin'
                        : _formatTimeOfDay(endTime!),
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

          // ──────────────────────────────── Boutons ─────────────────────────────────────────
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context, null),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () {
                // ───────── Validation rapide ─────────
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

                // Coherence horaire
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

                // ───────── Retour de la Map séance ─────────
                Navigator.pop(context, {
                  'titre': titreCtrl.text.trim(),
                  'date': Timestamp.fromDate(selectedDate!),
                  'heureDebut': _formatTimeOfDay(startTime!),
                  'heureFin': _formatTimeOfDay(endTime!),
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
  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  /// Ex. 01/07/2025  (tu l’as sans doute déjà)
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';


}
