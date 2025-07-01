import 'package:firstproject/models/user.dart';
import 'package:firstproject/pages/add_event_page.dart';
import 'package:firstproject/pages/authenticate/authenticate.dart';
import 'package:firstproject/pages/authenticate/sign_in.dart';
import 'package:firstproject/pages/eventpage.dart';
import 'package:firstproject/pages/wrapper.dart';
import 'package:firstproject/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';





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
          debugShowCheckedModeBanner: false, // 👈 Ajoute cette ligne

          home:wrapper()
      ),
    );
}

}

