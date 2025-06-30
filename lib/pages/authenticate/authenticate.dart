import 'package:firstproject/pages/authenticate/register.dart';
import 'package:firstproject/pages/authenticate/sign_in.dart';
import 'package:flutter/material.dart';

class authenticate extends StatefulWidget {

  const authenticate({super.key});

  @override
  State<authenticate> createState() => _authenticateState();
}

class _authenticateState extends State<authenticate> {

  bool showSignIn=true;
  void toggleView(){
    setState(() => showSignIn=!showSignIn);
  }
  @override
  Widget build(BuildContext context) {
    if(showSignIn){
      return SignIn(toggleView: toggleView);
    }else{
      return register(toggleView: toggleView);
    }

  }
}
