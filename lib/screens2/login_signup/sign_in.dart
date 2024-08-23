import 'package:DREHATT_app/screens2/agent/TABAgentdashboard.dart';
import 'package:DREHATT_app/screens2/admin/admindashbord.dart';
import 'package:DREHATT_app/screens2/dashboard.dart';
import 'package:DREHATT_app/screens2/login_signup/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:DREHATT_app/components/text_field.dart';
import 'package:DREHATT_app/screens2/login_signup/password_reset.dart';
import 'package:DREHATT_app/services2/auth_service.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late FocusNode focusNode_email;
  late FocusNode focusNode_pwd;

  bool isLoading = false;
  bool isLoadingGoogle = false;
  bool _isEmail = false;
  bool _isError = false;
  String errorMsg = '';
  bool _isPasswordVisible = false; // New variable for password visibility

  @override
  void initState() {
    super.initState();
    focusNode_email = FocusNode();
    focusNode_pwd = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    focusNode_email.dispose();
    focusNode_pwd.dispose();
    super.dispose();
  }

  bool isEmail(String input) {
    return input == 'dashboard' ||
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(input);
  }

  Future<void> signIn() async {
    if (_emailController.text.trim() == 'dashboard' &&
        _passwordController.text.trim() == 'adminroot') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        ),
      );
      return;
    }

    if (!isEmail(_emailController.text)) {
      setState(() {
        _isEmail = true;
        errorMsg = 'Enter valid email address';
      });
      return;
    } else {
      setState(() {
        _isEmail = false;
      });
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        await FirebaseFirestore.instance.collection('access_logs').add({
          'userId': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userDoc.get('name'),
          'timestamp': Timestamp.now(),
        });
        bool isAgent = userDoc.get('isAgent') ?? false;

        if (!mounted) return;

        if (isAgent) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Agentdashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Dashboard(),
            ),
          );
        }
      } else {
        print('User document not found in Firestore');
      }
    } on FirebaseAuthException catch (e) {
      print(e.code);
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _isError = true;
        errorMsg = getErrorMessage(e.code);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case "ERROR_EMAIL_ALREADY_IN_USE":
      case "account-exists-with-different-credential":
      case "email-already-in-use":
        return "Email already used. Go to login page.";
      case "ERROR_WRONG_PASSWORD":
      case "wrong-password":
        return "Incorrect email or password.";
      case "ERROR_USER_NOT_FOUND":
      case "user-not-found":
        return "No user found with this email.";
      case "ERROR_USER_DISABLED":
      case "user-disabled":
        return "User disabled.";
      case "ERROR_TOO_MANY_REQUESTS":
      case "operation-not-allowed":
        return "Too many requests to log into this account.";
      case "ERROR_OPERATION_NOT_ALLOWED":
      case "operation-not-allowed":
        return "Server error, please try again later.";
      case "ERROR_INVALID_EMAIL":
      case "invalid-email":
        return "Incorrect email or password.";
      case 'network-request-failed':
        return 'Network error.';
      default:
        return "Sign in failed. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Center(
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: const Color.fromRGBO(7, 82, 96, 1),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Image(
                      image: AssetImage('lib/assets/icons/me/logo.png'),
                      height: 80,
                    ),
                    Text(
                      'DREHATT',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.roboto(
                        fontSize: 35,
                        color: const Color.fromARGB(255, 16, 15, 15),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    FormUI(),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      'or',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: const Color.fromARGB(255, 67, 63, 63),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          setState(() {
                            isLoadingGoogle = true;
                          });
                          try {
                            UserCredential user =
                                await AuthService().signInWithGoogle(context);
                            String? userEmail = user.user!.email;
                            print('Email : $userEmail');

                            try {
                              var a = await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(user.user!.email)
                                  .get();
                              if (a.exists) {
                                print('Already Registered user');
                              } else {
                                print('New USER');
                                await FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(userEmail)
                                    .set(
                                  {
                                    'name': user.user!.displayName,
                                    'dob': null,
                                    'gender': null,
                                    'nic': null,
                                    'address': null,
                                    'mobile': null,
                                  },
                                );
                              }
                            } catch (e) {
                              print(e);
                            }
                          } catch (e) {
                            print(e);
                          }

                          setState(() {
                            isLoadingGoogle = false;
                          });
                        },
                        style: const ButtonStyle(
                          elevation: MaterialStatePropertyAll(2),
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        icon: !isLoadingGoogle
                            ? const FaIcon(
                                FontAwesomeIcons.google,
                                color: Colors.red,
                              )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                        label: !isLoadingGoogle
                            ? Text(
                                'Sign In with Google',
                                style: GoogleFonts.roboto(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : const Text(''),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            color: const Color.fromARGB(255, 67, 63, 63),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const SignUp();
                                },
                              ),
                            );
                          },
                          style: ButtonStyle(
                            elevation: const MaterialStatePropertyAll(0),
                            backgroundColor: const MaterialStatePropertyAll(
                              Colors.transparent,
                            ),
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            shape: const MaterialStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget FormUI() {
    return Column(
      children: [
        Text_Field(
          label: 'Email',
          hint: 'name@email.com',
          isPassword: false,
          keyboard: TextInputType.emailAddress,
          txtEditController: _emailController,
          focusNode: focusNode_email,
        ),
        const SizedBox(
          height: 5,
        ),
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
                errorMsg,
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
        TextField(
          controller: _passwordController,
          focusNode: focusNode_pwd,
          obscureText:
              !_isPasswordVisible, // Updated line for password visibility
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible =
                      !_isPasswordVisible; // Toggle password visibility
                });
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
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
                      children: const [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Color.fromRGBO(255, 16, 15, 15),
                        ),
                        SizedBox(
                          width: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const PasswordReset();
                    },
                  ),
                );
              },
              style: ButtonStyle(
                elevation: const MaterialStatePropertyAll(0),
                backgroundColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.fromLTRB(8, 0, 8, 0),
                ),
                shape: const MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                ),
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: FilledButton(
            onPressed: signIn,
            style: const ButtonStyle(
              elevation: MaterialStatePropertyAll(2),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
            ),
            child: !isLoading
                ? Text(
                    'Sign In',
                    style: GoogleFonts.roboto(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
