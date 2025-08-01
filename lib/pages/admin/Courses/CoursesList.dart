import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:firstproject/models/user.dart'; // Assurez-vous que le chemin est correct
import 'package:firstproject/services/auth.dart'; // Assurez-vous que le chemin est correct

// Nouvelles importations pour le téléchargement de fichiers
import 'package:file_picker/file_picker.dart'; // Pour choisir n'importe quel type de fichier
import 'package:path/path.dart' as p; // Pour la manipulation des chemins
import 'dart:io'; // Pour File
import 'package:path_provider/path_provider.dart'; // Pour les répertoires locaux
import 'package:http/http.dart' as http; // Pour le téléchargement
import 'package:permission_handler/permission_handler.dart'; // Pour les permissions

class CoursesPage extends StatefulWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  MyUser? _currentUser;
  bool _isLoadingUser = true;
  String? _selectedFormationId; // To store the selected formation's ID
  String? _selectedFormationTitle; // To store the selected formation's title

  final sb.SupabaseClient _supabase = sb.Supabase.instance.client; // Initialisation du client Supabase

  // Define your colors and InputDecoration here, or ensure they are accessible
  final Color oleaPrimaryReddishOrange = const Color(0xFFB7482B);
  final Color oleaSecondaryBrown = const Color(0xFF936037);
  final Color oleaLightBeige = const Color(0xFFE3D9C0);

  InputDecoration commonDropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      prefixIcon: Icon(icon, color: oleaPrimaryReddishOrange),
      filled: true,
      fillColor: oleaLightBeige.withOpacity(.35),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: oleaSecondaryBrown, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: oleaPrimaryReddishOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getCurrentUserData();
    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }

  Future<List<String>> getAllFormationIds() async {
    if (_currentUser == null || _currentUser?.role != 'superadmin') {
      print('Current user not loaded.');
      return [];
    }

    final firestore = FirebaseFirestore.instance;
    List<String> formationIds = [];

    try {
      final QuerySnapshot formationSnapshot = await firestore.collection('formations').get();

      for (var doc in formationSnapshot.docs) {
        formationIds.add(doc.id);
      }
    } catch (e) {
      print('Error getting all formation IDs: $e');
    }

    return formationIds;
  }

  // Fonction pour ajouter un cours avec le lien du fichier
  Future<bool> addCourseWithFormationLink({
    required String courseTitle,
    required String firebaseFormationId,
    String? documentUrl, // Nouveau paramètre pour l'URL du document
  }) async {
    final supabase = _supabase; // Utilisez l'instance de Supabase existante
    try {
      final response = await supabase.from('cours').insert({
        'title': courseTitle,
        'firebase_formation_id': firebaseFormationId,
        'document_url': documentUrl, // Insérer l'URL du document
      }).select();

      print('✅ Course added: $response');
      return true;
    } catch (e) {
      print('Error adding course: $e');
      return false;
    }
  }


  // --- NOUVELLE FONCTION : Nettoie un titre pour l'utiliser comme nom de dossier ---
  String _sanitizeFolderName(String title) {
    // Remplace les caractères non alphanumériques (sauf -, _) par des underscores
    // et supprime les multiples underscores consécutifs.
    return title
        .replaceAll(RegExp(r'[^\w\s\-]'), '') // Garde lettres, chiffres, espaces, tirets
        .replaceAll(' ', '_') // Remplace les espaces par des underscores
        .replaceAll(RegExp(r'_+'), '_') // Supprime les underscores multiples
        .trim(); // Supprime les espaces/underscores en début et fin
  }

  // --- NOUVELLE FONCTION : Détermine le nom du sous-dossier par type de fichier ---
  String _getFileTypeFolder(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'pdfs';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'images';
      case 'doc':
      case 'docx':
        return 'documents_word';
      case 'xls':
      case 'xlsx':
        return 'documents_excel';
      case 'ppt':
      case 'pptx':
        return 'documents_powerpoint';
      default:
        return 'others'; // Dossier par défaut pour les types inconnus
    }
  }


  // Fonction pour uploader un fichier vers Supabase Storage
  Future<void> _uploadFile() async {
    if (_selectedFormationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une formation pour lier le cours.')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'], // Adaptez les extensions
      );

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun fichier sélectionné.')));
        return;
      }

      final PlatformFile pickedFile = result.files.single;
      final File file = File(pickedFile.path!);
      final fileName = pickedFile.name; // Nom du fichier d'origine
      final fileExtension = pickedFile.extension;


      // Déterminer le contentType (MIME type)
      String? contentType = pickedFile.extension != null
          ? 'application/${pickedFile.extension}'
          : 'application/octet-stream'; // Par défaut si extension inconnue
      if (fileExtension == 'doc' || fileExtension == 'docx') {
        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Chemin du fichier dans le bucket "cours", sous-dossier "uploads"
      final sanitizedFormationTitle = _sanitizeFolderName(_selectedFormationTitle!);
      final fileTypeFolder = _getFileTypeFolder(fileExtension);
      final filePathInStorage = 'uploads/$sanitizedFormationTitle/$fileTypeFolder/$timestamp-$fileName';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement de $fileName en cours...')),
      );

      // Upload du fichier vers le bucket 'cours' de Supabase Storage
      final fileBytes = await file.readAsBytes();
      await _supabase.storage.from('cours').uploadBinary(
        filePathInStorage,
        fileBytes,
        fileOptions: sb.FileOptions(contentType: contentType, upsert: true),
      );

      // Obtenir l'URL publique du fichier uploadé
      final publicUrl = _supabase.storage.from('cours').getPublicUrl(filePathInStorage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Fichier uploadé avec succès')),
      );

      // Insérer une nouvelle ligne dans la table 'cours' avec le lien
      await addCourseWithFormationLink(
        courseTitle: fileName, // Utilisez le nom du fichier comme titre du cours, ou demandez à l'utilisateur
        firebaseFormationId: _selectedFormationId!,
        documentUrl: publicUrl, // Passez l'URL publique
      );

      // Rafraîchir la liste des cours après l'upload
      setState(() {
        // Pas besoin de recharger explicitement car StreamBuilder va écouter les changements
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur d\'upload : $e')),
      );
      print('❌ Erreur d\'upload : $e');
    }
  }


  // Fonction de téléchargement du fichier (ajoutée directement ici)
  Future<void> _downloadFile(String? fileUrl, String fileName) async {
    if (fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL du fichier non disponible.')),
      );
      return;
    }

    // 1. Demander les permissions de stockage
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de stockage non accordée.')),
      );
      return;
    }

    // 2. Obtenir le répertoire de téléchargement local
    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = await getDownloadsDirectory(); // Sur Android, cela va dans le dossier Téléchargements
    } else if (Platform.isIOS) {
      downloadsDirectory = await getApplicationDocumentsDirectory(); // Sur iOS, dans le dossier Documents de l'app
    }

    if (downloadsDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de trouver le répertoire de téléchargement.')),
      );
      return;
    }

    // Créer un sous-dossier pour les cours téléchargés dans le répertoire de l'application
    final String appDownloadsPath = downloadsDirectory.path;
    final String coursesFolderPath = '$appDownloadsPath/MesCoursTéléchargés'; // Nom du sous-dossier
    final Directory coursesFolder = Directory(coursesFolderPath);
    if (!await coursesFolder.exists()) {
      await coursesFolder.create(recursive: true);
    }

    final localPath = '$coursesFolderPath/$fileName';
    final saveFile = File(localPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Téléchargement de $fileName en cours...')),
    );

    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        await saveFile.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName téléchargé avec succès dans ${saveFile.path}')),
        );
        print('Fichier enregistré avec succés');
        OpenFilex.open(saveFile.path);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du téléchargement: ${response.statusCode}')),
        );
        print('Échec du téléchargement: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de téléchargement: $e')),
      );
      print('Erreur de téléchargement: $e');
    }
  }

  // --- NOUVELLE FONCTION : Supprimer un cours et son fichier associé ---
  Future<void> _deleteCourse(String courseId, String? documentUrl) async {
    // 1. Demander confirmation à l'utilisateur
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce cours et le fichier associé ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false; // Retourne false si la boîte de dialogue est fermée sans sélection

    if (!confirmDelete) {
      return; // L'utilisateur a annulé la suppression
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suppression en cours...')),
    );

    try {
      // 2. Supprimer le fichier de Supabase Storage (si une URL est présente)
      if (documentUrl != null && documentUrl.isNotEmpty) {
        try {
          // Extraire le chemin du fichier dans le bucket à partir de l'URL publique
          // L'URL publique est de la forme: https://[project-ref].supabase.co/storage/v1/object/public/bucket_name/path/to/file.ext
          // Nous avons besoin de 'path/to/file.ext'
          final Uri uri = Uri.parse(documentUrl);
          // Les segments sont [storage, v1, object, public, cours, uploads, Formation_Title, file_type, timestamp-filename.ext]
          // Nous voulons à partir de 'uploads'
          // L'index 4 est 'cours' (le nom du bucket), donc le chemin commence à l'index 5
          final String filePathInStorage = uri.pathSegments.sublist(5).join('/');
          print('Tentative de suppression du fichier dans le stockage : $filePathInStorage');
          await _supabase.storage.from('cours').remove([filePathInStorage]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier supprimé du stockage.')),
          );
        } catch (e) {
          print('Erreur lors de la suppression du fichier du stockage: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression du fichier du stockage: $e')),
          );
          // Ne pas retourner ici, car nous voulons quand même essayer de supprimer l'entrée de la BD
        }
      }

      // 3. Supprimer la ligne de la table 'cours'
      await _supabase.from('cours').delete().eq('id', courseId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Cours supprimé avec succès.')),
      );
      // Le StreamBuilder gérera la mise à jour de la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur de suppression: $e')),
      );
      print('❌ Erreur de suppression du cours: $e');
    }
  }


  // Fonction pour afficher les cours de Supabase
  Widget getAndDisplayUserCourses(String? currentSelectedFormationId) {
    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_currentUser == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return FutureBuilder<List<String>>(
      future: getAllFormationIds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("Aucune formation trouvée.");
          return const Center(child: Text('.'));
        }



        // Si aucune formation n'est sélectionnée, ou si la formation sélectionnée n'est pas dans celles de l'utilisateur
        if (currentSelectedFormationId == null) {
          return const Center(child: Text('Veuillez sélectionner une formation pour voir les cours.'));
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('cours').select().eq('firebase_formation_id', currentSelectedFormationId).asStream(),
          builder: (context, supabaseSnapshot) {
            if (supabaseSnapshot.connectionState == ConnectionState.waiting) {
              print("Connecting to Supabase and accessing 'cours' table...");
              return const Center(child: CircularProgressIndicator());
            }
            if (supabaseSnapshot.hasError) {
              return Center(child: Text('Error loading courses: ${supabaseSnapshot.error}'));
            }
            if (!supabaseSnapshot.hasData || supabaseSnapshot.data!.isEmpty) {
              print("Supabase connection successful, but no courses found for your formations.");
              return const Center(child: Text('Aucun cours trouvé pour cette formation.'));
            }

            final List<Map<String, dynamic>> courses = supabaseSnapshot.data!;

            print("Supabase connection successful. Accessed 'cours' table.");
            print("Course IDs found:");
            for (var course in courses) {
              print("  - ${course['id'] ?? 'N/A'} (Title: ${course['title'] ?? 'No Title'}) - Formation ID: ${course['firebase_formation_id'] ?? 'N/A'} - Document URL: ${course['document_url'] ?? 'N/A'}");
            }

            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final String? courseId = course['id']?.toString(); // Assurez-vous d'avoir l'ID du cours
                final String? documentUrl = course['document_url'] as String?;
                // Extraire le nom du fichier de l'URL pour l'affichage et le nommage lors du téléchargement
                final String fileName = documentUrl != null ? p.basename(Uri.parse(documentUrl).path) : 'Fichier inconnu';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(course['title'] ?? 'Titre inconnu'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Formation ID: ${course['firebase_formation_id'] ?? 'N/A'}'),
                        if (documentUrl != null)
                          Text('Fichier : $fileName'), // Afficher le nom du fichier
                      ],
                    ),
                    trailing: Row( // --- MODIFICATION ICI : Utiliser un Row pour plusieurs icônes ---
                      mainAxisSize: MainAxisSize.min, // S'assure que la Row prend le moins de place possible
                      children: [
                        // Bouton de téléchargement
                        if (documentUrl != null)
                          IconButton(
                            icon: const Icon(Icons.download),
                            color: oleaPrimaryReddishOrange,
                            onPressed: () => _downloadFile(documentUrl, fileName),
                          ),
                        // Bouton de suppression (visible seulement pour superadmin)
                        if (_currentUser?.role == 'superadmin' && courseId != null) // S'assurer que le rôle est superadmin ET que l'ID du cours est disponible
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red, // Couleur de suppression typique
                            onPressed: () => _deleteCourse(courseId, documentUrl),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Cette fonction n'est plus strictement nécessaire pour la sélection dynamique
  // mais gardée pour compatibilité si vous l'utilisez ailleurs.
  Future<String?> getFirebaseFormationId(String formationDocId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot formationDoc = await firestore.collection('formations').doc(formationDocId).get();
      if (formationDoc.exists) {
        return formationDoc.id;
      } else {
        print('Formation not found with ID: $formationDocId');
        return null;
      }
    } catch (e) {
      print('Error getting Firebase formation ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Cours')),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('formations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final List<DropdownMenuItem<String>> formationItems = [];
                // --- MODIFICATION ICI : Boucle pour ajouter toutes les formations ---
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  formationItems.add(
                    DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['titre'] ?? 'Formation sans titre'),
                    ),
                  );
                }


                if (formationItems.isEmpty && !_isLoadingUser) {
                  return Column(
                    children: [
                      Text('Aucune formation disponible pour l\'ajout de cours..'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: null, // Disable button
                        child: const Text('Ajouter un nouveau cours'),
                      ),
                    ],
                  );
                }

                if (_selectedFormationId == null && formationItems.isNotEmpty) {
                  _selectedFormationId = formationItems.first.value;
                  _selectedFormationTitle = formationItems.first.child is Text ? (formationItems.first.child as Text).data : null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {});
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedFormationId,
                      decoration: commonDropdownDecoration(
                        label: 'Sélectionner une formation',
                        icon: Icons.school,
                      ),
                      items: formationItems,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFormationId = newValue;
                          _selectedFormationTitle = (snapshot.data!.docs
                              .firstWhere((doc) => doc.id == newValue)
                              .data() as Map<String, dynamic>?)?['titre'] as String? ?? 'Formation sans titre';
                        });
                      },
                      validator: (value) => value == null ? 'Veuillez sélectionner une formation' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_currentUser?.role == 'superadmin') // N'affiche le bouton que si l'utilisateur est superadmin
                      ElevatedButton(
                        onPressed: _uploadFile,
                        child: const Text('Uploader un nouveau cours'),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: getAndDisplayUserCourses(_selectedFormationId), // Display courses here
          ),
        ],
      ),
    );
  }
}