import 'package:firstproject/models/user.dart';
import 'package:firstproject/pages/add_event_page.dart';
import 'package:firstproject/pages/admin/AdminDepartmentsPage.dart';
import 'package:firstproject/pages/admin/AdminOrganismesPage.dart';
import 'package:firstproject/pages/admin/AdminProfilePage.dart';
import 'package:firstproject/pages/admin/AdminReunionsPage.dart';
import 'package:firstproject/pages/admin/AdminStatsPage.dart';
import 'package:firstproject/pages/admin/admin_users_page.dart';
import 'package:firstproject/pages/admin/dashboard.dart';
import 'package:firstproject/pages/authenticate/authenticate.dart';
import 'package:firstproject/pages/authenticate/sign_in.dart';
import 'package:firstproject/pages/eventpage.dart';
import 'package:firstproject/pages/user/FormationsdDisponibles.dart';
import 'package:firstproject/pages/user/HistoriqueFormations.dart';
import 'package:firstproject/pages/user/ProchainesFormations.dart';
import 'package:firstproject/pages/user/UserMessagerie.dart';
import 'package:firstproject/pages/user/UserReunions.dart';
import 'package:firstproject/pages/user/UserStatistiques.dart';
import 'package:firstproject/pages/user/userProfile.dart';
import 'package:firstproject/pages/wrapper.dart';
import 'package:firstproject/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';




final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Obligatoire pour l'async dans main
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
          //'/HomePage': (context) => const AdminDashboard(),
          '/users': (_) => AdminUsersPage(),
          '/departments': (_) => const AdminDepartmentsPage(),
          '/organismes': (_) => const AdminOrganismesPage(),
          '/statistiques': (_) => const AdminStatsPage(),
          '/Reunions': (_) => const AdminReunionsPage(),

          /* Routes de l'utilisateur*/
          '/userProfile': (context) => const UserProfileApp(),
          '/ProchainesFormations': (context) => const UserProchainesFormationsPage(),
          '/FormationsDisponibles': (context) => const UserFormationsDisponiblesPage(),
          '/HistoriquesFormations': (context) => const UserHistoriquesFormationsPage(),
          '/UserStatistiques': (context) => const UserstatistiquesPage(),
          '/UserMessagerie': (context) => const UserMessageriePage(),
          '/UserReunions': (context) => const UserReunionsPage(),











        },
          debugShowCheckedModeBanner: false, // 👈 Ajoute cette ligne

          home:wrapper()
      ),
    );
}

}



