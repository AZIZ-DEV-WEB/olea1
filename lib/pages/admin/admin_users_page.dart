import 'package:firstproject/pages/admin/users/updateUser.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../pages/admin/users/adduser.dart';
import '../../services/auth.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _selectedDepartment = 'Tous';
  String _selectedPoste = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await showDialog<bool>(
            context: context,
            builder: (_) => const AddUserDialog(),
          );
          if (added == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User added successfully')),
                );
              }
            });
          }
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<MyUser>>(
        stream: MyUser.streamUsers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }

          final users = snap.data ?? [];

          final filteredUsers = _filteredUsers(users);

          if (users.isEmpty) {
            return const Center(child: Text('Aucun utilisateur.'));
          }

          final totalusers = users.length;

          final departmentList = [
            'Tous',
            ...users
                .map((u) => u.department.trim())
                .toSet()
                .where((d) => d.isNotEmpty),
          ];

          return LayoutBuilder(
            builder: (ctx, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiques',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: c.maxWidth < 600 ? 2 : 4,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _statCard('Utilisateurs', '$totalusers', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🔍 Barre de filtres
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      DropdownButton<String>(
                        value: _selectedDepartment,
                        items: departmentList.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedDepartment = val);
                        },
                        hint: const Text('Département'),
                      ),

                      DropdownButton<String>(
                        value: _selectedPoste,
                        items:
                            {
                              'Tous',
                              ...users
                                  .map((u) => u.poste.trim())
                                  .toSet()
                                  .where((p) => p.isNotEmpty),
                            }.toList().map((poste) {
                              return DropdownMenuItem(
                                value: poste,
                                child: Text(poste),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPoste = val);
                        },
                        hint: const Text('Poste'),
                      ),

                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Recherche nom/email',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text('Liste', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),

                  // 🧾 Liste filtrée
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredUsers.length,
                    itemBuilder: (ctx, i) => Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                filteredUsers[i].email[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.blue,
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filteredUsers[i].email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    filteredUsers[i].department,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    final updated = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => EditUserDialog(
                                        user: filteredUsers[i],
                                      ),
                                    );
                                    if (updated == true && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Utilisateur modifié avec succès',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await _confirmDelete(
                                      context,
                                      filteredUsers[i],
                                    );
                                    if (confirmed == true) {
                                      await AuthService().deleteUser(
                                        filteredUsers[i],
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Utilisateur supprimé'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🟦 Statistique
  Widget _statCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(12), // ↓ padding réduit
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(
        10,
      ), // coins un peu moins arrondis si tu veux
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18, // ↓ taille réduite
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4), // ↓ espacement réduit
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 12, color: color), // ↓ taille du label
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );


  // 🗑️ Confirmation suppression
  Future<bool?> _confirmDelete(BuildContext context, MyUser user) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer l’utilisateur "${user.username}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // 🔍 Filtres
  List<MyUser> _filteredUsers(List<MyUser> users) {
    return users.where((user) {
      final matchesDepartment =
          _selectedDepartment == 'Tous' ||
          user.department.trim().toLowerCase() ==
              _selectedDepartment.trim().toLowerCase();

      final matchesPoste =
          _selectedPoste == 'Tous' ||
          user.poste.trim().toLowerCase() ==
              _selectedPoste.trim().toLowerCase();

      final matchesSearch =
          _searchQuery.trim().isEmpty ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesDepartment && matchesPoste && matchesSearch;
    }).toList();
  }
}
