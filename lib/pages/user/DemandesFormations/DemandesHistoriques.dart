import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/models/user.dart';
import 'package:firstproject/services/auth.dart';

class Demandeshistoriques extends StatefulWidget {
  const Demandeshistoriques({super.key});

  @override
  State<Demandeshistoriques> createState() => _DemandeshistoriquesState();
}

class _DemandeshistoriquesState extends State<Demandeshistoriques> {
  final AuthService _auth = AuthService();
  MyUser? _currentUser;
  bool _isLoading = true;

  // Controllers for the search bars
  final TextEditingController _titleSearchController = TextEditingController();
  String _selectedStatusFilter = ''; // Empty string means no filter selected

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Add listeners to the text controller to trigger a rebuild on text changes
    _titleSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _titleSearchController.removeListener(_onSearchChanged);
    _titleSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuild the UI when the search text changes
    });
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUserData();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des demandes"),
        backgroundColor: const Color(0xFFB7482B),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _titleSearchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par titre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatusFilter.isEmpty ? null : _selectedStatusFilter,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par statut',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'accepted', child: Text('Acceptée')),
                      DropdownMenuItem(value: 'rejected', child: Text('Refusée')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('formationRequests')
                  .where('userId', isEqualTo: _currentUser!.uid)
                  .where('status', whereIn: ['accepted', 'rejected'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucune demande trouvée."));
                }

                // Apply filters
                final String titleSearchQuery = _titleSearchController.text.toLowerCase();
                final String statusFilter = _selectedStatusFilter;

                final filteredDemandes = snapshot.data!.docs.where((doc) {
                  final demande = doc.data() as Map<String, dynamic>;
                  final titre = (demande['title'] ?? '').toLowerCase();
                  final status = (demande['status'] ?? '').toLowerCase();

                  // Title filter
                  bool matchesTitle = titleSearchQuery.isEmpty || titre.contains(titleSearchQuery);

                  // Status filter
                  bool matchesStatus = statusFilter.isEmpty || status == statusFilter;

                  return matchesTitle && matchesStatus;
                }).toList();
                if (filteredDemandes.isEmpty) {
                  return const Center(child: Text("Aucune demande ne correspond à vos critères."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDemandes.length,
                  itemBuilder: (context, index) {
                    final demande = filteredDemandes[index].data() as Map<String, dynamic>;

                    final titre = demande['title'] ?? 'Titre inconnu';
                    final description = demande['description'] ?? '';
                    final status = demande['status'] ?? 'unknown';
                    final date = demande['createdAt'] != null
                        ? (demande['createdAt'] as Timestamp).toDate()
                        : null;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📚 Formation : $titre", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                            const Divider(),

                            // Détails Demande
                            if (description.isNotEmpty) Text("📝 $description"),
                            if (date != null)
                              Text("📅 Date de demande : ${date.day}/${date.month}/${date.year}"),

                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Chip(
                                  label: Text(
                                    status == 'accepted' ? 'Acceptée' : 'Refusée',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}