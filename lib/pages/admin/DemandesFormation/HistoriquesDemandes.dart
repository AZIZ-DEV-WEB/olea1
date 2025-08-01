import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth.dart';
import '../../../models/user.dart';

// Ensure these color definitions match your OLEA design system
final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
final Color oleaPrimaryDarkGray = const Color(0xFF666666);
final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
final Color oleaLightBeige = const Color(0xFFE3D9C0);

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: oleaPrimaryReddishOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label : $value',
            style: TextStyle(
              fontSize: 14,
              color: oleaPrimaryDarkGray,
            ),
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
        title: const Text('Historique des demandes'),
        backgroundColor: oleaPrimaryReddishOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('formationRequests')
        // Using whereIn to fetch documents with 'accepted' OR 'rejected' status
            .where('status', whereIn: ['accepted', 'rejected'])
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune demande trouvée dans l\'historique.'));
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoRow('Nom', userName, Icons.person), // 👤
                      const SizedBox(height: 8),
                      _buildInfoRow('Email', email, Icons.email), // 📧
                      const SizedBox(height: 8),
                      _buildInfoRow('Département', department, Icons.apartment), // 🏢
                      const SizedBox(height: 8),
                      _buildInfoRow('Poste', poste, Icons.work), // 💼
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