import 'package:firstproject/models/user.dart';
import 'package:firstproject/pages/admin/AdminDepartmentsPage.dart';
import 'package:firstproject/pages/admin/AdminOrganismesPage.dart';
import 'package:firstproject/pages/admin/AdminProfilePage.dart';
import 'package:firstproject/pages/admin/AdminReunionsPage.dart';
import 'package:firstproject/pages/admin/AdminStatsPage.dart';
import 'package:firstproject/pages/admin/DemandesFormation/DemandesFormations.dart';
import 'package:firstproject/pages/admin/admin_users_page.dart';
import 'package:firstproject/pages/authenticate/forgot_password.dart';
import 'package:firstproject/pages/authenticate/verificationEmail.dart';
import 'package:firstproject/pages/loading.dart';
import 'package:firstproject/pages/user/DemandesFormations/DemandesDashboard.dart';
import 'package:firstproject/pages/user/FormationsdDisponibles.dart';
import 'package:firstproject/pages/user/HistoriqueFormations.dart';
import 'package:firstproject/pages/user/PrgSeances.dart';
import 'package:firstproject/pages/user/ProchainesFormations.dart';
import 'package:firstproject/pages/user/UserCourses.dart';
import 'package:firstproject/pages/user/userProfile.dart';
import 'package:firstproject/pages/wrapper.dart';
import 'package:firstproject/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';




// Gestionnaire de messages en arrière-plan (doit être une fonction de haut niveau)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Assurez-vous que Firebase est initialisé ici aussi
  print("Handling a background message: ${message.messageId}");
  // Logique de traitement des messages en arrière-plan
}






final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'formation_channel_id',
    'Invitations Formations',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );
  await Supabase.initialize(
    url: 'https://rkotlysvmpqvilnqxszy.supabase.co', // ton URL Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrb3RseXN2bXBxdmlsbnF4c3p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MTE0MDgsImV4cCI6MjA2OTI4NzQwOH0.CHEFqr1qk3N8O-edLcrrc-O0nVWrOk-e2YDJr5S6f6U', // trouvé dans Settings > API
  );


  await flutterLocalNotificationsPlugin.initialize(settings);// Obligatoire pour l'async dans main
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    // 🔐 Demander la permission de recevoir des notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission de notification accordée');

      // 🎯 Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      print("🔥 FCM Token: $token");

      // 🎯 Gestion des messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 Message reçu en premier plan: ${message.notification?.title}");

      });

      // 🎯 Gestion des messages si l'app est ouverte par une notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("📲 L'application a été ouverte via une notification");
        // Exemple : navigation vers une page
        // navigatorKey.currentState?.pushNamed('/Mes Séances');
      });

    } else {
      print('🚫 Autorisation de notifications refusée');
    }
  }

  @override

  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
          navigatorKey: navigatorKey, // 👈 ici
        routes: {
          /* Routes de l'admin*/
          '/profile': (context) => const AdminProfileApp(),
          '/users': (_) => AdminUsersPage(),
          '/departments': (_) => const AdminDepartmentsPage(),
          '/organismes': (_) => const AdminOrganismesPage(),
          '/statistiques': (_) => const AdminStatsPage(),
          '/Reunions': (_) => const AdminReunionsPage(),
          '/DemandesFormations': (_) => const Demandesformations(),

          /* Routes de l'utilisateur*/


          '/Mes Séances': (context) => const PrgSeancesPage(),
          '/userProfile': (context) => const UserProfileApp(),
          '/ProchainesFormations': (context) => const UserProchainesFormationsPage(),
          '/FormationsDisponibles': (context) => const UserFormationsDisponiblesPage(),
          '/HistoriquesFormations': (context) => const UserHistoriquesFormationsPage(),
          '/MesCours': (context) => const MesCoursPage(),
          '/verification': (context) => const EmailVerificationPage(username: '', department: '', poste: '', email: '',),
          '/forgotPassword': (context) => const ForgotPasswordPage(),
          '/DemandesDashboard': (context) => const DemandesDashboard(),


        },
          debugShowCheckedModeBanner: false, // 👈 Ajoute cette ligne
          home:SplashScreen()
      ),
    );
}

}



