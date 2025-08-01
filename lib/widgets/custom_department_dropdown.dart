import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firstproject/services/auth.dart'; // Assuming MyUser is in this path
import '../models/user.dart'; // Import your MyUser model

/// Define OLEA colors here or in a separate theme file for global access
const Color oleaPrimaryOrange = Color(0xFFFF9800); // A vibrant orange for OLEA
const Color oleaDarkOrange = Color(0xFFD22D01); // A darker shade of OLEA orange
const Color oleaLightOrange = Color(0xFFFFF3E0); // A very light shade for backgrounds
const Color oleaGreyText = Color(0xFF424242); // Dark grey for general text
const Color oleaLightGrey = Color(0xFFEEEEEE); // Light grey for borders/backgrounds

/// -------------------------
/// SERVICE FIRESTORE
/// -------------------------
class DepartmentService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDepartments() async {
    final snap = await _firestore.collection('departments').get();
    return snap.docs.map((d) => d['name'].toString()).toList();
  }

  /// Stream des utilisateurs (role=user) d’un département
  Stream<List<MyUser>> usersByDepartment(String department) {
    return _firestore
        .collection('users')
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data();
      return MyUser(
        uid: doc.id,
        email: data['email'] as String? ?? '',
        username: data['username'] as String? ?? '',
        department: data['department'] as String? ?? '',
        poste: data['poste'] as String? ?? '',
        role: data['role'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? '',
        joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        emailVerified: data['emailVerified'] as bool? ?? false,
      );
    }).toList());
  }
}

/// -------------------------
/// WIDGET PRINCIPAL
/// -------------------------
class DepartmentUserTable extends StatefulWidget {
  final void Function(Map<String, Set<MyUser>>) onChanged;
  final Map<String, Set<MyUser>>? initialSelection; // pré‑sélection
  final bool readOnly; // mode lecture seule

  const DepartmentUserTable({
    super.key,
    required this.onChanged,
    this.initialSelection,
    this.readOnly = false,
  });

  @override
  State<DepartmentUserTable> createState() => _DepartmentUserTableState();
}

/// -------------------------
/// COLONNE (département)
/// -------------------------
class _DepartmentColumn extends StatelessWidget {
  final String department;
  final Stream<List<MyUser>> usersStream;
  final Set<MyUser> selected;
  final void Function(MyUser, bool) onToggle;
  final bool readOnly;

  const _DepartmentColumn({
    required this.department,
    required this.usersStream,
    required this.selected,
    required this.onToggle,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, // Fixed width for each column
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department name header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              department,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: oleaGreyText, // OLEA themed text color
              ),
            ),
          ),
          // User list
          StreamBuilder<List<MyUser>>(
            stream: usersStream,
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final users = snap.data!;
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('Aucun utilisateur',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final user = users[i];
                  // Check if the user is selected by comparing UIDs
                  final isSelected = selected.any((sUser) => sUser.uid == user.uid);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(
                      user.username, // Display the username
                      style: const TextStyle(
                          fontSize: 13, color: oleaGreyText), // OLEA themed text color
                    ),
                    value: isSelected,
                    onChanged: readOnly ? null : (v) => onToggle(user, v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: oleaPrimaryOrange, // OLEA orange for active checkbox
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// -------------------------
/// STATE DU WIDGET
/// -------------------------
class _DepartmentUserTableState extends State<DepartmentUserTable> {
  final _svc = DepartmentService();
  final Map<String, Set<MyUser>> _selectedUsers = {}; // état global, stores MyUser objects

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedUsers.addAll(widget.initialSelection!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background for the card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Slightly more visible shadow
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- HEADER ----------------
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  oleaPrimaryOrange.withOpacity(0.1),
                  oleaPrimaryOrange.withOpacity(0.05)
                ], // Subtle OLEA gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: oleaPrimaryOrange.withOpacity(0.2), // Lighter OLEA shade
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business_center_outlined,
                      color: oleaDarkOrange, size: 20), // Darker OLEA orange icon
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sélection par département',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: oleaGreyText)), // OLEA themed text
                      const SizedBox(height: 2),
                      Text('Glissez horizontalement pour voir tous les départements',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600], // Neutral grey for less important text
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Icon(Icons.swipe_left_outlined,
                    color: oleaPrimaryOrange, size: 18), // OLEA orange swipe icon
              ],
            ),
          ),

          // ---------------- CONTENU PRINCIPAL ----------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<String>>(
              future: _svc.getDepartments(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: oleaPrimaryOrange)), // OLEA colored loading
                  );
                }
                final deps = snap.data!;

                if (deps.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Aucun département trouvé.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: deps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dep = entry.value;
                      _selectedUsers.putIfAbsent(dep, () => <MyUser>{});

                      return Container(
                        margin: EdgeInsets.only(right: index < deps.length - 1 ? 16 : 0),
                        width: 200, // Consistent width for columns
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bouton select/deselect all
                            if (!widget.readOnly)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 36),
                                  // Foreground color based on selection status
                                  foregroundColor: _selectedUsers[dep]!.isEmpty
                                      ? oleaPrimaryOrange // OLEA orange for 'Select All'
                                      : Colors.red, // Red for 'Deselect All'
                                ),
                                icon: Icon(
                                  _selectedUsers[dep]!.isEmpty
                                      ? Icons.check_circle_outline
                                      : Icons.remove_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedUsers[dep]!.isEmpty
                                      ? 'Tout sélectionner'
                                      : 'Tout désélectionner',
                                  style: const TextStyle(fontSize: 12), // Text color handled by foregroundColor
                                ),
                                onPressed: () async {
                                  final allUsers =
                                  await _svc.usersByDepartment(dep).first;
                                  setState(() {
                                    if (_selectedUsers[dep]!.isEmpty) {
                                      _selectedUsers[dep] = allUsers.toSet();
                                    } else {
                                      _selectedUsers[dep]!.clear();
                                    }
                                  });
                                  widget.onChanged(_selectedUsers);
                                },
                              ),
                            if (!widget.readOnly) const SizedBox(height: 4),

                            // Liste des users
                            _DepartmentColumn(
                              department: dep,
                              usersStream: _svc.usersByDepartment(dep),
                              selected: _selectedUsers[dep]!,
                              onToggle: (user, checked) {
                                setState(() {
                                  if (checked) {
                                    _selectedUsers[dep]!.add(user);
                                  } else {
                                    // Remove the user based on UID to ensure correct removal
                                    _selectedUsers[dep]!.removeWhere((u) => u.uid == user.uid);
                                  }
                                });
                                widget.onChanged(_selectedUsers);
                              },
                              readOnly: widget.readOnly,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // ---------------- FOOTER ----------------
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: oleaLightGrey, // Light grey background for footer
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey.shade300)), // Slightly darker border
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: oleaPrimaryOrange, size: 16), // OLEA orange icon
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sélections: ${_selectedUsers.values.fold<int>(0, (s, set) => s + set.length)} utilisateur${_selectedUsers.values.fold<int>(0, (s, set) => s + set.length) > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: oleaGreyText), // OLEA themed text
                  ),
                ),
                if (_selectedUsers.values.any((set) => set.isNotEmpty))
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: oleaPrimaryOrange.withOpacity(0.2), // Light OLEA orange for 'Actif' background
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Actif',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: oleaDarkOrange)), // Darker OLEA orange for 'Actif' text
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}