import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstproject/pages/admin/users/updateUser.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../pages/admin/users/adduser.dart';
import '../../widgets/custom_app_bar.dart'; // Assurez-vous que CustomAppBar est bien personnalisé avec OLEA
import '../../services/auth.dart';

// --- OLEA Color Palette ---
// It's good practice to define these globally or in a theme file.
// Placed here for self-containment for this example.
const Color oleaPrimaryReddishOrange = Color(0xFFB7482B); // Primary action color
const Color oleaPrimaryOrange = Color(0xFFF8AF3C);      // Secondary accent, potentially for highlights
const Color oleaPrimaryDarkGray = Color(0xFF666666);    // General text and neutral elements
const Color oleaSecondaryDarkBrown = Color(0xFF432918); // Darker text for titles/headings
const Color oleaLightBeige = Color(0xFFE3D9C0);         // Page background

// -------------------------------------------------------------------
// AdminUsersPage: Page principale de gestion des utilisateurs
// -------------------------------------------------------------------
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  // --- State Variables (Functional, Not Touched) ---
  String? currentUserRole;
  String? _username;
  String _selectedDepartment = 'Tous';
  String _selectedPoste = 'Tous';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // --- Lifecycle Methods (Functional, Not Touched) ---
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchCtrl.addListener(() {
      // Listener to update _searchQuery in real-time as user types
      if (_searchCtrl.text.trim().toLowerCase() != _searchQuery) {
        setState(() {
          _searchQuery = _searchCtrl.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          currentUserRole = userDoc.data()?['role'];
          _username = userDoc.data()?['username'];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- Filtering Logic (Functional, Not Touched) ---
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

  // --- Dialog for Delete Confirmation (Functional, Not Touched) ---
  Future<bool?> _confirmDelete(BuildContext context, MyUser user) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmation de suppression', style: TextStyle(color: oleaSecondaryDarkBrown)),
        content: Text(
          'Voulez-vous vraiment supprimer l’utilisateur "${user.username}" ?',
          style: TextStyle(color: oleaPrimaryDarkGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: oleaPrimaryDarkGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // --- UI Building Methods (Reformatted, Functional Logic Preserved) ---

  // Build the Search Filters Section
  Widget _buildFilterSection(List<MyUser> allUsers) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 380;

    final double containerPadding = isSmallScreen ? 8.0 : 12.0;
    final double titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final double fieldLabelFontSize = isSmallScreen ? 14.0 : 16.0;
    final double fieldIconSize = isSmallScreen ? 18.0 : 20.0;
    final double rowSpacing = isSmallScreen ? 8.0 : 12.0;
    final double verticalSpacing = isSmallScreen ? 12.0 : 16.0;

    // Collect unique departments and postes for dropdowns
    final departmentList = [
      'Tous',
      ...allUsers
          .map((u) => u.department.trim())
          .toSet()
          .where((d) => d.isNotEmpty),
    ];
    final posteList = [
      'Tous',
      ...allUsers
          .map((u) => u.poste.trim())
          .toSet()
          .where((p) => p.isNotEmpty),
    ];

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres de recherche',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: oleaSecondaryDarkBrown,
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: verticalSpacing),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email',
              hintStyle: TextStyle(
                color: oleaPrimaryDarkGray.withOpacity(0.7),
                fontSize: fieldLabelFontSize,
              ),
              prefixIcon: Icon(Icons.search, color: oleaPrimaryReddishOrange, size: fieldIconSize),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12, horizontal: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: oleaPrimaryDarkGray, size: fieldIconSize),
                onPressed: () {
                  _searchCtrl.clear();
                  // No need to setState for _searchQuery here, listener handles it
                },
              )
                  : null,
            ),
            // onChanged is handled by _searchCtrl.addListener now for better performance
            // and immediate _searchQuery update.
            style: TextStyle(fontSize: fieldLabelFontSize),
          ),
          SizedBox(height: verticalSpacing),
          isVerySmallScreen
              ? Column(
            children: [
              _buildDepartmentDropdown(departmentList, fieldLabelFontSize, fieldIconSize),
              SizedBox(height: verticalSpacing),
              _buildPosteDropdown(posteList, fieldLabelFontSize, fieldIconSize),
            ],
          )
              :
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 24,
                child: _buildDepartmentDropdown(departmentList, fieldLabelFontSize, fieldIconSize),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 24,
                child: _buildPosteDropdown(posteList, fieldLabelFontSize, fieldIconSize),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Department Dropdown
  Widget _buildDepartmentDropdown(List<String> departmentList, double fontSize, double iconSize) {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        labelText: 'Département',
        labelStyle: TextStyle(color: oleaPrimaryDarkGray, fontSize: fontSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      ),
      items: departmentList.map((dept) {
        return DropdownMenuItem(
          value: dept,
          child: Text(dept, style: TextStyle(color: oleaPrimaryDarkGray, fontSize: fontSize)),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedDepartment = val!);
      },
      icon: Icon(Icons.arrow_drop_down, color: oleaPrimaryReddishOrange, size: iconSize),
    );
  }

  // Build Poste Dropdown
  Widget _buildPosteDropdown(List<String> posteList, double fontSize, double iconSize) {
    return DropdownButtonFormField<String>(
      value: _selectedPoste,
      decoration: InputDecoration(
        labelText: 'Poste',
        labelStyle: TextStyle(color: oleaPrimaryDarkGray, fontSize: fontSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      ),
      items: posteList.map((poste) {
        return DropdownMenuItem(
          value: poste,
          child: Text(poste, style: TextStyle(color: oleaPrimaryDarkGray, fontSize: fontSize)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPoste = val);
      },
      icon: Icon(Icons.arrow_drop_down, color: oleaPrimaryReddishOrange, size: iconSize),
    );
  }

  // Build the User List
  Widget _buildUserList(List<MyUser> filteredUsers) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      itemBuilder: (ctx, i) => Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              CircleAvatar(
                backgroundColor: oleaPrimaryReddishOrange,
                child: Text(
                  filteredUsers[i].username.isNotEmpty ? filteredUsers[i].username[0].toUpperCase() : filteredUsers[i].email[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filteredUsers[i].username.isNotEmpty
                          ? filteredUsers[i].username
                          : filteredUsers[i].email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: oleaSecondaryDarkBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final dept = (filteredUsers[i].department?.trim().isNotEmpty == true)
                          ? filteredUsers[i].department!
                          : 'Sans département';
                      final poste = filteredUsers[i].poste?.trim().isNotEmpty == true
                          ? filteredUsers[i].poste!
                          : '—';
                      return Text(
                        '$dept • $poste',
                        style: TextStyle(
                          fontSize: 14,
                          color: oleaPrimaryDarkGray,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Row(
                children: [
                  if (currentUserRole == 'superadmin') ...[
                    IconButton(
                      icon: Icon(Icons.edit, color: oleaPrimaryReddishOrange),
                      onPressed: () async {
                        final updated = await showDialog<bool>(
                          context: context,
                          builder: (_) => EditUserDialog(user: filteredUsers[i]),
                        );
                        if (updated == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Utilisateur modifié avec succès')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await _confirmDelete(context, filteredUsers[i]);
                        if (confirmed == true) {
                          await AuthService().deleteUser(filteredUsers[i]);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Utilisateur supprimé')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        username: _username,
        getAppBarTitle: () => 'Gestion des utilisateurs',
        onLogout: () async {
          await AuthService().signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
      ),
      backgroundColor: oleaLightBeige,
      floatingActionButton: currentUserRole == 'superadmin'
          ? FloatingActionButton(
        onPressed: () async {
          final added = await showDialog<bool>(
            context: context,
            builder: (_) => const AddUserDialog(),
          );
          if (added == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilisateur ajouté avec succès')),
                );
              }
            });
          }
        },
        backgroundColor: oleaPrimaryReddishOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un utilisateur',
      )
          : null,
      body: StreamBuilder<List<MyUser>>(
        stream: MyUser.streamUsers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: oleaPrimaryReddishOrange));
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}', style: const TextStyle(color: Colors.red)));
          }

          final users = snap.data ?? [];
          final filteredUsers = _filteredUsers(users); // Apply filters to the fetched users

          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Aucun utilisateur enregistré.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: oleaPrimaryDarkGray),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSection(users), // Pass all users to filter section to populate dropdowns
                const SizedBox(height: 24),
                Text(
                  'Liste des utilisateurs (${filteredUsers.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: oleaSecondaryDarkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildUserList(filteredUsers), // Build the list with filtered users
              ],
            ),
          );
        },
      ),
    );
  }
}