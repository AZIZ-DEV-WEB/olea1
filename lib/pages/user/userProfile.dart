import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


import '../../models/user.dart';
import '../../services/auth.dart';
import '../../widgets/department_dropdown.dart';
import 'UserDashboard.dart';

class UserProfileApp extends StatefulWidget {
  const UserProfileApp({Key? key}) : super(key: key);

  @override
  State<UserProfileApp> createState() => _UserProfileAppState();
}

class _UserProfileAppState extends State<UserProfileApp>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers pour les formulaires
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _posteController = TextEditingController();
  String? department;
  File? _selectedImage;
  String? _photoUrl;

  // États des toggles (non utilisés dans l'UI actuelle, mais conservés)
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _darkMode = false;
  bool _autoLogin = true;



  // Couleurs OLEA
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaPrimaryOrange = const Color(0xFFF8AF3C);
  final Color oleaSecondaryBrown = const Color(0xFF936037);
  final Color oleaPrimaryDarkGray = const Color(0xFF666666);
  final Color oleaSecondaryDarkBrown = const Color(0xFF432918);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);


  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _loadUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && mounted) {
          setState(() {
            _nameController.text = data['username'] ?? '';
            _emailController.text = firebaseUser.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _posteController.text = data['poste'] ?? '';
            department = data['department'] ?? '';
            _photoUrl = data['photoUrl'] ?? null;

          });
        }
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }


  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _posteController.dispose(); // Ajouté pour disposer le contrôleur de poste
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Couleurs OLEA pour le dégradé de fond
            colors: [oleaLightBeige, oleaSecondaryBrown], // Ex: Beige clair vers Marron secondaire
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNavBar(context),
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildResponsiveContent(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 800) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(
                  context,
                  // Utilisation de PushReplacement pour éviter d'empiler les pages
                  // et un PageRouteBuilder pour une transition personnalisée
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const UserDashboard(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(-1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Profil User',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildPersonalInfoCard(),
                      //const SizedBox(height: 24),
                      //_buildRecentActivityCard(), // Commenté car non implémenté
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Vous pouvez ajouter d'autres cartes ici pour le layout desktop
                Expanded(child: Column(children: [])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildPersonalInfoCard(),
          //const SizedBox(height: 24),
          //_buildRecentActivityCard(), // Commenté car non implémenté
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(), // Ajout de l'en-tête pour mobile
          const SizedBox(height: 20),
          _buildPersonalInfoCard()
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        // Dégradé OLEA pour le nom de l'utilisateur
                        colors: [oleaPrimaryReddishOrange, oleaPrimaryOrange],
                      ).createShader(bounds),
                      child: Text(
                        _nameController.text.isEmpty
                            ? 'Nom de l\'utilisateur'
                            : _nameController.text,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Couleur masquée par le shader
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _posteController.text.isEmpty
                          ? 'Utilisateur'
                          : _posteController.text,
                      style: TextStyle(fontSize: 18, color: oleaSecondaryDarkBrown), // Poste en Chocolat foncé OLEA
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _nameController.text.isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'A';

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: oleaLightBeige, // Fond de l'avatar en Beige clair OLEA
            image: _photoUrl != null
                ? DecorationImage(
              image: NetworkImage(_photoUrl!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: _photoUrl == null
              ? Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: oleaSecondaryDarkBrown, // Initiales en Chocolat foncé OLEA
              ),
            ),
          )
              : null,
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: oleaPrimaryReddishOrange, // Bouton d'édition en Rouge-Orange OLEA
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Fond de carte légèrement transparent blanc
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // Dégradé OLEA pour l'icône de titre de carte
                      colors: [oleaPrimaryReddishOrange, oleaPrimaryOrange],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: oleaSecondaryDarkBrown, // Titre de carte en Chocolat foncé OLEA
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      title: 'Informations personnelles',
      icon: Icons.person,
      child: Column(
        children: [
          _buildTextField('Nom complet', _nameController),
          const SizedBox(height: 16),
          _buildTextField('Email', _emailController, readOnly: true), // Email en lecture seule
          const SizedBox(height: 16),
          _buildTextField('Téléphone', _phoneController),
          const SizedBox(height: 16),
          _buildTextField('Poste', _posteController),
          const SizedBox(height: 16),
          DepartmentDropdown(

            selected: department,
            onChanged: (value) {
              setState(() {
                department = value;
              });
            },
          ),

          const SizedBox(height: 24),
          _buildActionButton('Sauvegarder les modifications', Icons.save),
          const SizedBox(height: 16), // Espace entre les boutons
          _buildSecondaryButton('Réinitialiser le mot de passe', Icons.lock_reset), // Exemple de bouton secondaire
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController? controller, {
        bool isPassword = false,
        String? Function(String?)? validator,
        bool readOnly = false, // Ajout de la propriété readOnly
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: oleaPrimaryDarkGray, // Label en Gris foncé OLEA
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          readOnly: readOnly, // Applique la propriété readOnly
          style: TextStyle(
            color: readOnly ? oleaPrimaryDarkGray : Colors.black87, // Couleur du texte pour lecture seule
          ),
          decoration: InputDecoration(
            hintText: isPassword ? '••••••••' : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            enabledBorder: OutlineInputBorder( // Ajout de enabledBorder pour cohérence
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2), // Focus OLEA
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          _saveUserData();
        },
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: Colors.white,
          backgroundColor: oleaPrimaryReddishOrange, // Bouton principal OLEA
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child:
      ElevatedButton.icon(
        icon: const Icon(Icons.lock_reset),
        label: const Text('Modifier mot de passe'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF8AF3C),
        ),
        onPressed: () => _showChangePasswordDialog(context),
      )
    );
  }


  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Changer le mot de passe',
            style: TextStyle(color: Color(0xFFB7482B), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildPasswordField(currentPasswordController, 'Mot de passe actuel'),
                const SizedBox(height: 10),
                _buildPasswordField(newPasswordController, 'Nouveau mot de passe'),
                const SizedBox(height: 10),
                _buildPasswordField(confirmPasswordController, 'Confirmer le nouveau mot de passe'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Color(0xFF666666))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF8AF3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (newPassword != confirmPassword) {
                  _showSnackBar(context, 'Les mots de passe ne correspondent pas.', false);
                  return;
                }

                if (newPassword.length < 6) {
                  _showSnackBar(context, 'Le mot de passe doit contenir au moins 6 caractères.', false);
                  return;
                }

                try {
                  final cred = EmailAuthProvider.credential(
                    email: currentUser!.email!,
                    password: currentPassword,
                  );

                  await currentUser.reauthenticateWithCredential(cred);
                  await currentUser.updatePassword(newPassword);

                  Navigator.pop(context); // Ferme le dialog

                  _showSnackBar(context, 'Mot de passe modifié avec succès.', true);
                } catch (e) {
                  _showSnackBar(context, 'Erreur : ${e.toString()}', false);
                }
              },
              child: const Text('Modifier', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFF8AF3C)),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, bool success) {
    final bgColor = success ? const Color(0xFFB7482B) : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }



  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      try {
        await docRef.update({
          'username': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'poste': _posteController.text.trim(),
          'department': department?.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modifications enregistrées avec succès !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'enregistrement : ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${user.uid}.jpg');

        try {
          await storageRef.putFile(file);
          final downloadUrl = await storageRef.getDownloadURL();

          // Mise à jour Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'photoUrl': downloadUrl});

          setState(() {
            _selectedImage = file;
            _photoUrl = downloadUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo de profil mise à jour !')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors du téléchargement de l\'image : ${e.toString()}')),
            );
          }
        }
      }
    }
  }
}
