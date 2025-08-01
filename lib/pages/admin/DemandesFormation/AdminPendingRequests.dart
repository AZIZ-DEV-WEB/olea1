import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth.dart';
import '../../../models/user.dart';
import '../../user/DemandesFormations/DeposerDemande.dart'; // adapte ce chemin

final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
final Color oleaPrimaryDarkGray = const Color(0xFF666666);
final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
final Color oleaLightBeige = const Color(0xFFE3D9C0);

class AdminPendingRequests extends StatefulWidget {
  const AdminPendingRequests({super.key});

  @override
  State<AdminPendingRequests> createState() => _AdminPendingRequestsState();
}

class _AdminPendingRequestsState extends State<AdminPendingRequests> {
  final AuthService _auth = AuthService();
  MyUser? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _auth.getCurrentUserData();
    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }


  String _formatDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return oleaPrimaryOrange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return oleaPrimaryDarkGray;
    }
  }

  // FIX 2: Moved _buildInfoRow inside the _AdminPendingRequestsState class
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: oleaPrimaryDarkGray,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: oleaPrimaryDarkGray),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('les demandes en attente'),
        backgroundColor: oleaPrimaryReddishOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _currentUser?.role == 'superadmin'
            ? FirebaseFirestore.instance
            .collection('formationRequests')
            .where('status', isEqualTo: 'pending')
            .where('departmentApproved', isEqualTo: true)
            .snapshots()
            : FirebaseFirestore.instance
            .collection('formationRequests')
            .where('status', isEqualTo: 'pending')
            .where('departmentApproved', isEqualTo: false)
            .where('departement', isEqualTo: _currentUser?.department)
            .snapshots(),

        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune demande trouvée.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final userName = data['userName'] ?? 'Inconnu';
              final email = data['email'] ?? 'Inconnu';
              final title = data['title'] ?? '';
              final description = data['description'] ?? '';
              final department = data['departement'] ?? '';
              final poste = data['poste'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final status = data['status'] ?? '';
              final adminComment = data['adminComment'] ?? '';


              return Card(
                color: oleaLightBeige.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: oleaPrimaryDarkGray.withOpacity(0.3)),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) Entête : utilisateur + date
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: oleaPrimaryReddishOrange,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.info_outline, color: oleaPrimaryOrange),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: oleaLightBeige.withOpacity(0.9),
                                  title: Text(
                                    'Infos utilisateur',
                                    style: TextStyle(
                                      color: oleaSecondaryDarkBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildInfoRow('Nom', userName),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Email', email),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Département', department),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Poste', poste),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Fermer',
                                        style: TextStyle(color: oleaPrimaryReddishOrange),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: oleaPrimaryDarkGray,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 2) Titre de la demande
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: oleaSecondaryDarkBrown,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 3) Description
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: oleaPrimaryDarkGray,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4) Statut actuel
                      Row(
                        children: [
                          Text(
                            'Statut : ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: oleaPrimaryDarkGray,
                            ),
                          ),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ],
                      ),

                      // 5) Boutons Accepter/Refuser si en attente
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                if (_currentUser?.role == 'superadmin') {
                                  // Superadmin valide la demande définitivement
                                  await docs[i].reference.update({
                                    'status': 'accepted',
                                  });
                                } else if (_currentUser?.role == 'admin') {
                                  // Responsable de département valide vers superadmin
                                  await docs[i].reference.update({
                                    'departmentApproved': true,
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: oleaPrimaryOrange,
                              ),
                              child: const Text('Accepter'),
                            ),

                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                await docs[i].reference.update({'status': 'rejected'});
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: oleaPrimaryReddishOrange,
                              ),
                              child: const Text('Refuser'),
                            ),
                          ],
                        ),
                      ],

                      // 6) Commentaire RH (si existant)
                      if ((adminComment as String).isNotEmpty) ...[
                        const Divider(height: 24, color: Colors.transparent),
                        Text(
                          'Commentaire RH :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: oleaPrimaryDarkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminComment,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: oleaPrimaryDarkGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}