import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:date_field/date_field.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {

  // Clé pour identifier le formulaire et pouvoir valider son contenu
  final _formKey = GlobalKey<FormState>();
  final confNameController = TextEditingController();
  final sujetController = TextEditingController();
  DateTime selectedConfDate=DateTime.now(); // Declare selectedDate here,
  String selectedConfType=  'talk';
  final avatarcontroller=  TextEditingController();
  @override
  void dispose(){
    super.dispose();
    confNameController.dispose();
    sujetController.dispose();
    avatarcontroller.dispose();
  }
  Widget build(BuildContext context) {
    return
      Container(
        margin: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Nom de la Conference",
                      hintText: "Entrer le nom de la conference",
                      border: OutlineInputBorder()
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Tu dois compléter ce texte";
                      }
                      return null;
                    },
                    controller: confNameController,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: TextFormField(
                    decoration: InputDecoration(
                        labelText: "Sujet de la Conference",
                        hintText: "Entrer le Sujet de la conference",
                        border: OutlineInputBorder()
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Tu dois compléter ce texte";
                      }
                      return null;
                    },
                    controller: sujetController,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField(
                      items: const [
                        DropdownMenuItem(value: 'talk' , child: Text('talk show')),
                        DropdownMenuItem(value: 'demo' , child: Text('Demo code')),
                        DropdownMenuItem(value: 'partner' , child: Text('Partner')),
                      ],
                      decoration:InputDecoration(
                        border: OutlineInputBorder()
                      ),
                      value: selectedConfType,
                      onChanged: (value){
                        setState(() {
                          selectedConfType=value!;
                        });
                      }
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: DateTimeFormField(
                    decoration: const InputDecoration(
                      labelText: 'Enter Date',
                    ),
                    firstDate: DateTime.now().add(const Duration(days: 10)),
                    lastDate: DateTime.now().add(const Duration(days: 40)),
                    initialPickerDateTime: DateTime.now().add(const Duration(days: 20)),
                    onChanged: (DateTime? value) {
                      setState(() { // Use setState to update the UI if needed
                        selectedConfDate = value!;
                      });
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: TextFormField(
                    decoration: InputDecoration(
                        labelText: "Avatar de la Conference",
                        hintText: "Entrer le Avatar de la conference",
                        border: OutlineInputBorder()
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Tu dois compléter ce texte";
                      }
                      return null;
                    },
                    controller: avatarcontroller,
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: (){
                        if(_formKey.currentState!.validate()){
                          final confName = confNameController.text;
                          final sujetName = sujetController.text;
                          final type = selectedConfType;
                          final avatar = avatarcontroller.text;
                          final date = selectedConfDate;

                          ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Envoi en cours.")),
                          );
                          FocusScope.of(context).requestFocus(FocusNode());
                          CollectionReference eventsRef = FirebaseFirestore.instance.collection('Events');
                          eventsRef.add({
                            'confName': confName,
                            'sujet': sujetName,
                            'type': selectedConfType,
                            'date': selectedConfDate,
                            'avatar': avatar,
                          });

                          print("Ajout de la conference : $confName");
                          print("Sujet : $sujetName");
                          print("Type de conference : $selectedConfType");
                          if (selectedConfDate != null) { // Also print the selected date
                            print("Date sélectionnée : $selectedConfDate");
                          }
                              }
                      },
                      child: Text("Envoyer")
                  ),
                ),



              ],
            )
        ),
      );
  }
}



