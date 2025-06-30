import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstproject/pages/admin/home.dart';
import 'package:firstproject/widgets/custom_department_dropdown.dart';
import 'package:intl/intl.dart';


import '../../services/auth.dart';
import '../../widgets/modalités.dart';
import '../../widgets/organismes.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});


  @override

  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, Set<String>> _selectedUsers = {};
  List<Map<String, dynamic>> _calendrier = [];
  Set<String> _expandedFormations = {};
  final AuthService _auth = AuthService(); // Ajouter dans ta classe _AdminHomeState
  String? _username;

  int _currentIndex = 0;

  // Controllers pour le formulaire d'ajout
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  final _dureController = TextEditingController();
  String? _selectedModalite;
  String? _organismeId;




  String? _chosenDepartment;
  String? _chosenUser;// user sélectionné dans cette colonne





  Future<void> _loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _username = doc['username']; // ou 'nom' selon ton champ Firestore
      });
    }
  }




  List<Map<String, dynamic>> formations = [];

  List<Map<String, dynamic>> participants = [];   // champs d'état

  List<Map<String, dynamic>> refus = [
    {
      'nom': 'Sami Bouaziz',
      'departement': 'Commercial',
      'cause': 'Conflit d\'horaire avec réunion client importante'
    },
    {
      'nom': 'Nadia Mejri',
      'departement': 'Production',
      'cause': 'Absence pour congé maladie'
    },
    {
      'nom': 'Hichem Ghanmi',
      'departement': 'Finance',
      'cause': 'Formation non pertinente pour le poste actuel'
    },
  ];


  @override
  void initState() {
    super.initState();
    _loadUsername(); // Charge le nom de l'utilisateur dès que la page est ouverte
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar utilisateur + nom
            if (_username != null) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _username!.isNotEmpty ? _username![0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bonjour,',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    _username!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Espaceur flexible
            const Spacer(),

            // Titre centré
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            // Espaceur flexible
            const Spacer(),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.blue[900]?.withOpacity(0.5),
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[700]!,
                Colors.blue[800]!,
                Colors.blue[900]!,
              ],
            ),
          ),
        ),
        actions: [
          // Notifications (optionnel)
          IconButton(
            onPressed: () {
              // Action notifications
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                // Badge de notification (optionnel)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
          ),

          const SizedBox(width: 8),

          // Menu utilisateur
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                // Ouvrir profil
                  break;
                case 'settings':
                // Ouvrir paramètres
                  break;
                case 'logout':
                  await _auth.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),

                  ],
                ),
              ),
            ],
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
            tooltip: 'Menu',
          ),

          const SizedBox(width: 16),
        ],
      ),      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          _buildFormationsListPage(),
          _buildAddFormationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Formations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Ajouter',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tableau de Bord Admin';
      case 1:
        return 'Liste des Formations';
      case 2:
        return 'Ajouter une Formation';
      default:
        return 'Admin';
    }
  }

  // Page 1: Home (Tableau de bord)
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques
          _buildStatsCards(),
          SizedBox(height: 24),

          // Bloc Participants
          _buildParticipantsBlock(),
          SizedBox(height: 24),

          // Bloc Refus
          _buildRefusBlock(),
        ],
      ),
    );
  }

  // Page 2: Liste des formations
  Widget _buildFormationsListPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('formations').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erreur lors du chargement des formations.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune formation disponible.'));
        }

        final formations = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;        // ←  on injecte l’ID du document
          return data;
        }).toList();


        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toutes les Formations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: formations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final formation = formations[index];
                  return _buildFormationCard(formation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _ouvrirPopupCalendrier() {
    // variables locales à la popup
    DateTime  date       = DateTime.now();
    TimeOfDay heureDebut = const TimeOfDay(hour: 9,  minute: 0);
    TimeOfDay heureFin   = const TimeOfDay(hour: 12, minute: 0);
    String    titre      = '';

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
                      (heureFin.hour == picked.hour && heureFin.minute <= picked.minute)) {
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
                  final finMinutes   = heureFin.hour   * 60 + heureFin.minute;
                  if (finMinutes <= debutMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Heure de fin avant l’heure de début')),
                    );
                    return;
                  }
                  // ➜ ajoute la séance
                  setState(() {
                    _calendrier.add({
                      'date'      : date,
                      'heureDebut': heureDebut,
                      'heureFin'  : heureFin,
                      'titre'     : titre,
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
      setState(() {});                    // pour rafraîchir l’aperçu éventuel
    });
  }
  Widget _buildCalendrierPreview() {
    if (_calendrier.isEmpty) {
      return const Text(
        'Aucune séance ajoutée.',
        style: TextStyle(color: Colors.grey),
      );
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _calendrier.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final date = s['date'] as DateTime;
        final heureDebut = s['heureDebut'];
        final heureFin = s['heureFin'];
        final titre = s['titre'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.event_note, color: Colors.blue),
            title: Text(titre ?? 'Sans titre'),
            subtitle: Text(
              '📅 ${_formatDate(date)} | 🕒 ${heureDebut.format(context)} - ${heureFin.format(context)}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _calendrier.removeAt(i);
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }


  // Page 3: Ajouter une formation
  Widget _buildAddFormationPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.blue[800], size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Nouvelle Formation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.event_available),
                  label: const Text('Ajouter une séance au calendrier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade100,
                    foregroundColor: Colors.indigo.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _ouvrirPopupCalendrier,
                ),

                SizedBox(height: 16),
                Text('Programme des séances', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildCalendrierPreview(),
                const SizedBox(height: 16),


                SizedBox(height: 24),
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre de la formation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir un titre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir une description';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),
                TextFormField(
                  controller: _dureController,
                  decoration: InputDecoration(
                    labelText: 'Durée de la formation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir une durée';
                    }
                    return null;
                    },
                ),
                SizedBox(height: 16),
                DropdownModalite(
                  selectedValue: _selectedModalite,
                  onChanged: (val) {
                    setState(() {
                      _selectedModalite = val;
                    });
                  },
                ),
                SizedBox(height: 16),
                OrganismeDropdown(
                  selectedId: _organismeId,
                  onChanged: (val) => setState(() => _organismeId = val),
                  validator: (val) =>
                  val == null ? 'Choisissez un organisme de formation' : null,
                ),

                SizedBox(height: 16),


                TextFormField(
                  controller: _dateDebutController,
                  decoration: InputDecoration(
                    labelText: 'Date de début de la formation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month),
                      onPressed: () => _selectDateDebut(context),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _dateFinController,
                  decoration: InputDecoration(
                    labelText: 'Date de fin de la formation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month),
                      onPressed: () => _selectDateFin(context),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),



                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DepartmentUserTable(
                      onChanged: (map) {
                        setState(() {
                          _selectedUsers = map;          // <-- maintenant autorisé
                        });
                      },
                    ),

                    if (_selectedUsers.values.every((set) => set.isEmpty))
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                      ),
                  ],
                ),


                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _ajouterFormation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter la Formation',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStatsCards() {
    return Row(
      children: [
        // ---------- Total formations ----------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('formations')
                .snapshots(),
            builder: (context, snap) {
              final total = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                'Total Formations',
                total.toString(),
                Icons.school,
                Colors.blue,
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // ---------- Participants acceptés ----------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('participations')
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
            builder: (context, snap) {
              final accepted = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                'Participants',
                accepted.toString(),
                Icons.group,
                Colors.green,
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // ---------- Refus ----------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('participations')
                .where('status', isEqualTo: 'refused')
                .snapshots(),
            builder: (context, snap) {
              final refused = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                'Refus',
                refused.toString(),
                Icons.cancel,
                Colors.red,
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationCard(Map<String, dynamic> formation) {
    // Définir une couleur selon le statut de la formation
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Titre + badge statut + bouton modifier
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formation['titre'] ?? 'Titre inconnu',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  tooltip: 'Modifier',
                  onPressed: () => _openEditSheet(context, formation['id'], formation),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

            // 🔹 Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, size: 20, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formation['description'] ?? 'Pas de description.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Durée
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timelapse, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Duré de la formation : ',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      formation['duré'] ?? 'Inconnue',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Heures : ',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Organisme de formation
            Row(
              children: [
                const Icon(Icons.domain, size: 16, color: Colors.grey),  // icône d’organisme
                const SizedBox(width: 4),
                Text(
                  'Organisme : ',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    formation['organismeNom'] ?? 'Inconnu',
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 🔹 Modalité
            Row(
              children: [
                const Icon(Icons.style, size: 16, color: Colors.grey),   // icône de modalité
                const SizedBox(width: 4),
                Text(
                  'Modalité : ',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                Text(
                  formation['modalite'] ?? 'Inconnue',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),


            // 🔹 Dates (début et fin)
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Début : ',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                Text(
                  formation['dateDebut'] ?? 'Inconnue',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Fin : ',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                Text(
                  formation['dateFin'] ?? 'Inconnue',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),
            //affichage des seances de formation
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Voir les séances"),
                  onPressed: () => _showSeancesDialog(context, formation),
                ),
              ],
            ),



            const SizedBox(height: 12),

            // 🔹 Participants
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text('Voir les participants'),
                  onPressed: () => _showParticipantsDialog(context, formation['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsBlock() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.green[700], size: 28),
                SizedBox(width: 12),
                Text(
                  'Employés Participants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${participants.length}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: participants.length > 3 ? 3 : participants.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final participant = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getParticipantStatusColor(participant['statut']),
                    child: Icon(
                      _getParticipantStatusIcon(participant['statut']),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    participant['nom'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(participant['departement']),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getParticipantStatusColor(participant['statut']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getParticipantStatusColor(participant['statut']),
                      ),
                    ),
                    child: Text(
                      participant['statut'],
                      style: TextStyle(
                        color: _getParticipantStatusColor(participant['statut']),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (participants.length > 3)
              TextButton(
                onPressed: () {
                  // Navigation vers liste complète
                },
                child: Text('Voir tous les participants'),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildRefusBlock() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[700], size: 28),
                SizedBox(width: 12),
                Text(
                  'Refus Récents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${refus.length}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: refus.length > 2 ? 2 : refus.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final refusItem = refus[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[700],
                    child: Icon(Icons.person_off, color: Colors.white),
                  ),
                  title: Text(
                    refusItem['nom'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(refusItem['departement']),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cause du refus:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              refusItem['cause'],
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Annulée':
        return Colors.red;
      case 'En cours':
        return Colors.orange;
      case 'Planifiée':
        return Colors.blue;
      case 'Terminée':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getParticipantStatusColor(String statut) {
    switch (statut) {
      case 'Confirmé':
        return Colors.green;
      case 'En attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getParticipantStatusIcon(String statut) {
    switch (statut) {
      case 'Confirmé':
        return Icons.check_circle;
      case 'En attente':
        return Icons.access_time;
      default:
        return Icons.help;
    }
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
        _dateDebutController.text = "${picked.day}/${picked.month}/${picked.year}";
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
        _dateFinController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }



  void _ajouterFormation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUsers.values.every((set) => set.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez au moins un participant')),
      );
      return;
    }

    final participants = _selectedUsers.entries
        .expand((entry) => entry.value.map((username) => {
      'username': username,
      'department': entry.key,
    }))
        .toList();
    final participantsCount = participants.length;  // ex. 3

    try {
      final calendrierFirestore = _calendrier.map((s) => {
        'date': Timestamp.fromDate(s['date']),
        'heureDebut': s['heureDebut'].format(context),
        'heureFin': s['heureFin'].format(context),
        'titre': s['titre'],
      }).toList();

      // 1. Créer la formation → on récupère son DocRef
      final docRef = await FirebaseFirestore.instance
          .collection('formations')
          .add({
        'titre'      : _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'statut'     : 'Planifiée',
        'createdAt'  : FieldValue.serverTimestamp(),
        'dateDebut'    : _dateDebutController.text.trim(),
        'dateFin'    : _dateFinController.text.trim(),
        'duré': _dureController.text.trim(),
        'modalite': _selectedModalite ?? '',
        'organismeId': _organismeId,
        'calendrier': calendrierFirestore,


        'participants' : participants,
        'participantsCount' : participantsCount,

      });

      // 2. Pour chaque user coché, créer un document participation
      final batch = FirebaseFirestore.instance.batch();

      for (final entry in _selectedUsers.entries) {
        final dept = entry.key;
        for (final username in entry.value) {
          // (facultatif) récupérer l'uid du user par son username
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

          final userId = userSnap.docs.isNotEmpty ? userSnap.docs.first.id : '';

          final partDoc = FirebaseFirestore.instance.collection('participations').doc();
          batch.set(partDoc, {
            'formationId': docRef.id,
            'userId'     : userId,
            'userName'   : username,
            'department' : dept,
            'status'     : 'invited',   // ou 'accepted', 'pending', etc.
          });
        }
      }

      await batch.commit(); // envoie toutes les participations

      // 3. Feedback + reset
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
        _currentIndex = 1; // retour liste formations
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  void _openEditSheet(BuildContext ctx, String id, Map<String, dynamic> data) {
    // Contrôleurs texte pré-remplis
    final titreCtrl = TextEditingController(text: data['titre']);
    final descCtrl = TextEditingController(text: data['description']);
    final departCtrl = TextEditingController(text: data['departement']);
    final dateDebutCTRL = TextEditingController(text: data['dateDebut']);
    final dateFinCTRL = TextEditingController(text: data['dateFin']); // ❗ Corrigé
    final dureCtrl = TextEditingController(text: data['duré']);

    // Valeurs sélectionnées
    String selectedStatut = data['statut']?.toString() ?? '';
    String selectedOrganisme = data['organismeNom']?.toString() ?? '';
    String? selectedModalite = data['modalite']?.toString();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Modifier la formation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titreCtrl,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: dateDebutCTRL,
                    decoration: const InputDecoration(labelText: 'Date début (yyyy-MM-dd)'),
                  ),
                  TextField(
                    controller: dateFinCTRL,
                    decoration: const InputDecoration(labelText: 'Date fin (yyyy-MM-dd)'),
                  ),
                  TextField(
                    controller: dureCtrl,
                    decoration: const InputDecoration(labelText: 'Durée'),
                  ),
                  const SizedBox(height: 12),

                  // Modalité
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('modalites')
                        .orderBy('label')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();

                      final modalites = snap.data!.docs
                          .map((d) => d['label'] as String)
                          .toList();

                      return DropdownButtonFormField<String>(
                        value: selectedModalite,
                        decoration: const InputDecoration(labelText: 'Modalité'),
                        items: modalites.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedModalite = val),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Organisme
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('organismesFormation')
                        .orderBy('nom')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();

                      final organismes = snap.data!.docs
                          .map((d) => d['nom'] as String)
                          .toList();

                      if (!organismes.contains(selectedOrganisme) && organismes.isNotEmpty) {
                        selectedOrganisme = organismes.first;
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedOrganisme,
                        decoration: const InputDecoration(labelText: 'Organisme'),
                        items: organismes.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedOrganisme = val!),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Statut
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('statuts')
                        .orderBy('label')
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();

                      final statuts = snap.data!.docs
                          .map((d) => d['label'] as String)
                          .toList();

                      if (!statuts.contains(selectedStatut) && statuts.isNotEmpty) {
                        selectedStatut = statuts.first;
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedStatut,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: statuts.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedStatut = val!),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Bouton enregistrer
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

                      Navigator.pop(ctx); // Ferme la BottomSheet
                    },
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

//fonction pour afficher les seances de formation dans un popup
void _showSeancesDialog(BuildContext context, Map<String, dynamic> formation) {
  final calendrier = formation['calendrier'] as List<dynamic>? ?? [];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.event_note, color: Colors.blue),
          SizedBox(width: 8),
          Text('Séances programmées'),
        ],
      ),
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
                title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${_formatDate(date)}   |   $heureDebut → $heureFin',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Fermer'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
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
              'IT'          : Icons.computer,
              'Santé'       : Icons.local_hospital,
              'Automobile'  : Icons.directions_car,
              'Voyages'     : Icons.flight_takeoff,
              'IRDS'        : Icons.security,
              'Finance'     : Icons.attach_money,
              'Comptabilité': Icons.business,
            };

            // --- Contenu de la popup ---
            return SizedBox(
              width: 350,
              child: ListView(
                shrinkWrap: true,
                children: parDept.entries.map((entry) {
                  final dept  = entry.key;
                  final list  = entry.value;

                  // séparer acceptés / refusés
                  final refuses  = list.where((p) => p['status'] == 'refused');
                  final invites  = list.where((p) =>
                  p['status'] == 'invited' || p['status'] == 'accepted');

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
                  if (refuses.isEmpty && acceptedNames.containsAll(totalUsers)) {
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
                  child: Icon(icon, size: 20, color: Colors.blueGrey),
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



// Fonction pour formater la date
String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }}