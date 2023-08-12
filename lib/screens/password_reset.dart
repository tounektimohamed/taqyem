import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mymeds_app/components/alert.dart';

import '../components/text_field.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final _emailController = TextEditingController();

  Future passwordReset() async {
    try {
      if (_emailController.text.isEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return const Alert_Dialog(
                isError: true,
                alertTitle: 'Error',
                errorMessage: 'Email can\'t be empty.',
                buttonText: 'Cancel');
          },
        );
      } else {
        //loading circle
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
        //pop loading cicle
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) {
            return const Alert_Dialog(
              isError: false,
              alertTitle: 'Alert',
              errorMessage: 'Password reset link sent! Check your email.',
              buttonText: 'Ok',
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      print(e);
      if (!mounted) {
        return;
      }
      //pop loading cicle
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) {
          return Alert_Dialog(
              isError: true,
              alertTitle: 'Error',
              errorMessage: e.message.toString(),
              buttonText: 'Cancel');
        },
      );
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
      // backgroundColor: const Color.fromARGB(255, 233, 237, 237),
      appBar: AppBar(
        // systemOverlayStyle: const SystemUiOverlayStyle(
        //     statusBarColor: Color.fromARGB(255, 233, 237, 237)),
        elevation: 5,
        // iconTheme: const IconThemeData(
        //   color: Color.fromRGBO(7, 82, 96, 1),
        // ),
        title: Text(
          'Reset your password',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            // color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        // backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
      ),
      body: Container(
        margin: const EdgeInsets.all(35),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //text
              Text(
                'Enter the email address associated with your account',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 16, 15, 15),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 15,
              ),
              //email txtfield
              Text_Field(
                label: 'Email',
                hint: 'name@email.com',
                isPassword: false,
                keyboard: TextInputType.emailAddress,
                txtEditController: _emailController,
              ),
              const SizedBox(
                height: 20,
              ),
              //button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: passwordReset,
                  style: const ButtonStyle(
                    elevation: MaterialStatePropertyAll(2),
                    // backgroundColor: MaterialStatePropertyAll(
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
                    'Reset Password',
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
}
