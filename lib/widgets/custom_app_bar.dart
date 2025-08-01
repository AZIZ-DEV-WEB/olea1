import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/admin/AdminNotifications.dart';
import '../pages/user/notifications.dart';
import '../pages/admin/AdminNotifications.dart';
import '../services/auth.dart';
import '../models/user.dart';

/// Couleurs OLEA
const Color _oleaGradientStart = Color(0xFFB62800);
const Color _oleaGradientEnd   = Color(0xFFF99E49);
const Color _oleaBeige         = Color(0xFFE3D9C0);
const Color _oleaBrownDark     = Color(0xFF442618);

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? username;
  final String Function() getAppBarTitle;
  final Future<void> Function() onLogout;

  const CustomAppBar({
    Key? key,
    required this.username,
    required this.getAppBarTitle,
    required this.onLogout,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  MyUser? _currentUser;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final u = await AuthService().getCurrentUserData();
    setState(() {
      _currentUser = u;
      _loading = false;
    });
  }

  void _onNotificationsPressed() {
    if (_currentUser == null) return;
    final role = _currentUser!.role;
    if (role == 'admin' || role == 'superadmin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminNotificationsPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    }
  }

  void _onProfileSelected() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = doc.data()?['role'];
    if (role == 'admin' || role == 'superadmin') {
      Navigator.pushNamed(context, '/profile');
    } else {
      Navigator.pushNamed(context, '/userProfile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_oleaGradientStart, _oleaGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 8,
      toolbarHeight: 70,

      foregroundColor: Colors.white,
      title: _loading
          ? const SizedBox()
          : LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return
            Row(
              children: [
                if (widget.username != null) ...[
                  CircleAvatar(
                    radius: isMobile ? 16 : 18,
                    backgroundColor: _oleaBeige,
                    child: Text(
                      widget.username!.isNotEmpty
                          ? widget.username![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: _oleaBrownDark,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      widget.username!,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  flex: 8, // ✅ Augmenté pour élargir le titre
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _oleaBeige,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _oleaBeige),
                    ),
                    child: Text(
                      widget.getAppBarTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: _oleaBrownDark,
                      ),
                    ),
                  ),
                ),
              ],
            );
        },
      ),

      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 24),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
          onPressed: _loading ? null : _onNotificationsPressed,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) async {
            if (value == 'profile') {
              _onProfileSelected();
            } else if (value == 'logout') {
              await widget.onLogout();
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _oleaBeige,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_vert, color: _oleaBrownDark),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 20, color: _oleaBrownDark),
                  SizedBox(width: 12),
                  Text('Mon profil',
                      style: TextStyle(color: _oleaBrownDark)),
                ],
              ),
            ),
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
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
