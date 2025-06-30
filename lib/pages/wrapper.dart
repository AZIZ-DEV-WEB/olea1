import 'package:firstproject/pages/authenticate/authenticate.dart';
import 'package:firstproject/pages/user/UserHomePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firstproject/models/user.dart';
import 'package:firstproject/pages/admin/home.dart';


class wrapper extends StatelessWidget {
  const wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);
    // Non connecté ⇒ écran Auth
    if(user == null)
      return  const authenticate();

    // Connecté ⇒ router selon le rôle
    switch(user.role) {
      case 'admin':
        return const AdminHome();
      default:
        return const Userhomepage();


    }

  }
}
