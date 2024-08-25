import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:DREHATT_app/components/alert.dart';

import '../../components/text_field.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final _emailController = TextEditingController();

  late FocusNode focusNode_email;

  bool _isEmail = false;
  bool _isRest = false;

  bool _isError = false;
  String errorMsg = '';

  bool isEmail(String input) => RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(input);

  @override
  void initState() {
    super.initState();
    focusNode_email = FocusNode();
  }

  Future passwordReset() async {
    if (_emailController.text.isEmpty) {
      focusNode_email.requestFocus();
    } else {
      if (!isEmail(_emailController.text)) {
        setState(() {
          _isEmail = true;
        });
      } else {
        setState(() {
          _isEmail = false;
        });
        try {
          // cercle de chargement
          showDialog(
            context: context,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color.fromRGBO(7, 82, 96, 1),
                ),
              );
            },
          );

          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: _emailController.text.trim(),
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _isRest = true;
            _isError = false;
          });
        } on FirebaseAuthException catch (e) {
          print('${e.code}');
          if (!mounted) {
            return;
          }

          // fermer le cercle de chargement
          Navigator.of(context).pop();

          setState(() {
            _isError = true;
            _isRest = false;
            errorMsg = getErrorMessage(e.code);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // couleur de fond : const Color.fromARGB(255, 233, 237, 237),
      appBar: AppBar(
        // style d'overlay système : const SystemUiOverlayStyle(
        //     statusBarColor: Color.fromARGB(255, 233, 237, 237)),
        elevation: 5,
        // thème de l'icône : const IconThemeData(
        //   color: Color.fromRGBO(7, 82, 96, 1),
        // ),
        title: Text(
          'Réinitialiser votre mot de passe',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            // couleur : const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        // couleur de fond : const Color.fromRGBO(7, 82, 96, 1),
      ),
      body: Container(
        margin: const EdgeInsets.all(35),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // texte
              Text(
                'Entrez l’adresse email associée à votre compte',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 16, 15, 15),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 15,
              ),
              // champ de texte email
              Text_Field(
                label: 'Email',
                hint: 'nom@email.com',
                isPassword: false,
                keyboard: TextInputType.emailAddress,
                txtEditController: _emailController,
                focusNode: focusNode_email,
              ),
              const SizedBox(
                height: 2,
              ),
              // texte email invalide
              Visibility(
                visible: _isEmail,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                    child: Text(
                      'Entrez une adresse email valide',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color.fromRGBO(255, 16, 15, 15),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              // message d'erreur firebase
              Visibility(
                visible: _isError,
                maintainSize: false,
                maintainAnimation: true,
                maintainState: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.right,
                      color: const Color.fromRGBO(255, 16, 15, 15),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color.fromRGBO(255, 16, 15, 15),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Text(
                            errorMsg,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromRGBO(255, 16, 15, 15),
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              // message de succès
              Visibility(
                visible: _isRest,
                maintainSize: false,
                maintainAnimation: true,
                maintainState: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: GlowingOverscrollIndicator(
                      axisDirection: AxisDirection.right,
                      color: const Color.fromARGB(239, 0, 198, 89),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color.fromARGB(239, 0, 198, 89),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Text(
                            'Lien de réinitialisation du mot de passe envoyé ! Vérifiez votre email.',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(239, 0, 198, 89),
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),
              // bouton
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: passwordReset,
                  style: const ButtonStyle(
                    elevation: MaterialStatePropertyAll(2),
                    // couleur de fond : MaterialStatePropertyAll(
                    //   Color.fromARGB(255, 7, 82, 96),
                    // ),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    'Réinitialiser le mot de passe',
                    style: GoogleFonts.roboto(
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // messages d'erreur firebase
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-disabled':
        return "Utilisateur désactivé.";
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'weak-password':
        return 'Veuillez entrer un mot de passe fort.';
      case 'invalid-action-code':
        return 'Code d’action invalide. Veuillez réessayer.';
      case 'expired-action-code':
        return 'Le code d’action est expiré.';
      case 'network-request-failed':
        return 'Erreur de réseau.';
      default:
        return 'Erreur lors de la réinitialisation du mot de passe.';
    }
  }
}
