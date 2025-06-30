import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// -------------------------
/// SERVICE FIRESTORE
/// -------------------------
class DepartmentService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDepartments() async {
    final snap = await _firestore.collection('departments').get();
    return snap.docs.map((d) => d['name'].toString()).toList();
  }

  /// retourne un stream de noms d’utilisateurs (role=user) filtré par département
  Stream<List<String>> usersByDepartment(String department) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => d['username'].toString()).toList());
  }
}

/// -------------------------
/// WIDGET PRINCIPAL
/// -------------------------
class DepartmentUserTable extends StatefulWidget {
  final void Function(Map<String, Set<String>>) onChanged; // 🔄 callback

  const DepartmentUserTable({super.key, required this.onChanged});

  @override
  State<DepartmentUserTable> createState() => _DepartmentUserTableState();
}

class _DepartmentColumn extends StatelessWidget {
  final String department;
  final Stream<List<String>> usersStream;
  final Set<String> selected;                      // ← utilisateurs cochés
  final void Function(String, bool) onToggle;      // ← (user, checked)

  const _DepartmentColumn({
    required this.department,
    required this.usersStream,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(department,
              style: const TextStyle(fontWeight: FontWeight.bold)),

          StreamBuilder<List<String>>(
            stream: usersStream,
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final users = snap.data!;
              if (users.isEmpty) return const Text('Aucun user');

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final user = users[i];
                  return CheckboxListTile(
                    dense: true,
                    title: Text(user, style: const TextStyle(fontSize: 13)),
                    value: selected.contains(user),
                    onChanged: (v) => onToggle(user, v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
/// COLONNE Département
/// -------------------------
class _DepartmentUserTableState extends State<DepartmentUserTable> {
  final _svc = DepartmentService();
  final Map<String, Set<String>> _selectedUsers = {}; // état global

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et indicateur de scroll
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.indigo.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_center_outlined,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélection par département',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Glissez horizontalement pour voir tous les départements',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.swipe_left_outlined,
                  color: Colors.blue.shade400,
                  size: 18,
                ),
              ],
            ),
          ),

          // Contenu principal avec FutureBuilder
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<String>>(
              future: _svc.getDepartments(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chargement des départements...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final deps = snap.data!;

                return Container(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 400,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicateur du nombre de départements
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${deps.length} département${deps.length > 1 ? 's' : ''} trouvé${deps.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scroll horizontal avec décoration
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade50,
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: deps.asMap().entries.map((entry) {
                                final index = entry.key;
                                final dep   = entry.value;

                                _selectedUsers.putIfAbsent(dep, () => <String>{});

                                // 🔹 On met tout dans une Column : le bouton + _DepartmentColumn
                                return Container(
                                  margin: EdgeInsets.only(right: index < deps.length - 1 ? 16 : 0),
                                  width : 200,
                                  child : Column(
                                    children: [
                                      // ------------- BOUTON TOUT SÉLECTIONNER / DÉSÉLECTIONNER -------------
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          minimumSize: Size(double.infinity, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        icon: Icon(
                                          _selectedUsers[dep]!.isEmpty
                                              ? Icons.check_circle_outline   // rien ⇒ on propose "tout sélectionner"
                                              : Icons.remove_circle_outline, // déjà sélection ⇒ "tout désélectionner"
                                          color: _selectedUsers[dep]!.isEmpty ? Colors.green : Colors.red,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _selectedUsers[dep]!.isEmpty
                                              ? 'Tout sélectionner'
                                              : 'Tout désélectionner',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _selectedUsers[dep]!.isEmpty ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        onPressed: () async {
                                          // Récupère la liste complète des users de ce département
                                          final allUsers = await _svc.usersByDepartment(dep).first;
                                          setState(() {
                                            if (_selectedUsers[dep]!.isEmpty) {
                                              _selectedUsers[dep] = allUsers.toSet();  // sélectionne tout
                                            } else {
                                              _selectedUsers[dep]!.clear();            // désélectionne tout
                                            }
                                          });
                                          widget.onChanged(_selectedUsers);             // notifie parent
                                        },
                                      ),

                                      const SizedBox(height: 4),

                                      // ---------------------- LISTE DES UTILISATEURS ----------------------
                                      _DepartmentColumn(
                                        department : dep,
                                        usersStream: _svc.usersByDepartment(dep),
                                        selected   : _selectedUsers[dep]!,
                                        onToggle   : (user, checked) {
                                          setState(() {
                                            if (checked) {
                                              _selectedUsers[dep]!.add(user);
                                            } else {
                                              _selectedUsers[dep]!.remove(user);
                                            }
                                          });
                                          widget.onChanged(_selectedUsers);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer avec résumé des sélections
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sélections: ${_selectedUsers.values.fold(0, (sum, set) => sum + set.length)} utilisateur${_selectedUsers.values.fold(0, (sum, set) => sum + set.length) > 1 ? 's' : ''} sélectionné${_selectedUsers.values.fold(0, (sum, set) => sum + set.length) > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (_selectedUsers.values.any((set) => set.isNotEmpty))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Actif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }}
