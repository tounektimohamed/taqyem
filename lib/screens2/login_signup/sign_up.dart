import 'package:DREHATT_app/screens2/login_signup/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/text_field.dart';
import '../../services2/auth_service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

enum Genders { male, female, other }

class _SignUpState extends State<SignUp> {
  //controllers - keep track what types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();

  late FocusNode focusNode_email;
  late FocusNode focusNode_pwd;
  late FocusNode focusNode_pwdConfirm;
  late FocusNode focusNode_name;
  late FocusNode focusNode_dob;
  late FocusNode focusNode_gender;

  bool _isEmail = false;
  bool _isName = false;
  bool _isPwd = false;
  bool _isPwdConfirm = false;

  bool isLoading = false;
  bool isLoadingGoogle = false;

  bool _isError = false;
  bool _isSuccess = false;
  //firebase error message
  String errorMsg = '';

  Genders? _genderSelected;

  bool isName(String input) => RegExp(r'^[a-zA-Z]').hasMatch(input);
  bool isEmail(String input) => RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(input);
  bool isPassword(String input) =>
      RegExp(r'^.{8,}$')
          .hasMatch(input);

  @override
  void initState() {
    focusNode_email = FocusNode();
    focusNode_pwd = FocusNode();
    focusNode_pwdConfirm = FocusNode();
    focusNode_name = FocusNode();
    focusNode_dob = FocusNode();
    focusNode_gender = FocusNode();
    super.initState();
  }

  bool isPasswordConfirmed() {
    if (_passwordController.text.trim() ==
        _confirmpasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }
Future signUp() async {
  if (_nameController.text.isEmpty) {
    focusNode_name.requestFocus();
  } else if (_emailController.text.isEmpty) {
    focusNode_email.requestFocus();
  } else if (_passwordController.text.isEmpty) {
    focusNode_pwd.requestFocus();
  } else if (_confirmpasswordController.text.isEmpty) {
    focusNode_pwdConfirm.requestFocus();
  } else {
    // Validate input fields
    if (!isName(_nameController.text)) {
      setState(() {
        _isName = true;
      });
      return;
    } else {
      setState(() {
        _isName = false;
      });
    }
    if (!isEmail(_emailController.text)) {
      setState(() {
        _isEmail = true;
      });
      return;
    } else {
      setState(() {
        _isEmail = false;
      });
    }
    if (!isPassword(_passwordController.text)) {
      setState(() {
        _isPwd = true;
      });
      return;
    } else {
      setState(() {
        _isPwd = false;
      });
    }

    // Check if passwords match
    if (!isPasswordConfirmed()) {
      setState(() {
        _isPwdConfirm = true;
      });
      return;
    } else {
      setState(() {
        _isPwdConfirm = false;
      });
    }

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user data to Firestore
      await FirebaseFirestore.instance.collection('Users').doc(userCredential.user!.uid).set(
        {
          'name': _nameController.text.trim(),
          'dob': null,
          'gender': null,
          'nic': null,
          'address': null,
          'mobile': null,
          'isAgent': false, // Ajout du champ isAgent avec valeur par défaut false
        },
      );

      setState(() {
        _isError = false;
        _isSuccess = true;
        isLoading = false;
      });

      // Handle success UI or navigation here
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isError = true;
        _isSuccess = false;
        isLoading = false;
        errorMsg = getErrorMessage(e.code);
      });
    }
  }
}


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Center(
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: const Color.fromARGB(255, 7, 83, 96),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        //text
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Let\'s \nGet Started',
                            style: GoogleFonts.roboto(
                              fontSize: 35,
                              height: 1.0,
                              color: const Color.fromARGB(255, 16, 15, 15),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            //logo
                            const Image(
                              image:
                                  AssetImage('lib/assets//icons/me/logo.png'),
                              height: 50,
                            ),
                            //title
                            Text(
                              'DREHATT',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromRGBO(7, 82, 96, 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 40,
                    ),

                    //name
                    Text_Field(
                      label: 'Name',
                      hint: 'FirstName LastName',
                      isPassword: false,
                      keyboard: TextInputType.text,
                      txtEditController: _nameController,
                      focusNode: focusNode_name,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    //text not a valid name
                    Visibility(
                      visible: _isName,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                          child: Text(
                            'Enter a valid name',
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

                    //email
                    Text_Field(
                      label: 'Email',
                      hint: 'name@email.com',
                      isPassword: false,
                      keyboard: TextInputType.emailAddress,
                      txtEditController: _emailController,
                      focusNode: focusNode_email,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    //text not a valid email
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
                            'Enter a valid email address',
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

                    //password
                    Text_Field(
                      label: 'Password',
                      hint: 'Password',
                      isPassword: true,
                      keyboard: TextInputType.visiblePassword,
                      txtEditController: _passwordController,
                      focusNode: focusNode_pwd,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    //text not a valid password
                    Visibility(
                      visible: _isPwd,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                          child: Text(
                            'Enter a strong password',
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

                    //confirm password
                    Text_Field(
                      label: 'Confirm Password',
                      hint: 'Password',
                      isPassword: true,
                      keyboard: TextInputType.visiblePassword,
                      txtEditController: _confirmpasswordController,
                      focusNode: focusNode_pwdConfirm,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    //text password mismatch
                    Visibility(
                      visible: _isPwdConfirm,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                          child: Text(
                            'Passwords do not match',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color.fromRGBO(255, 16, 15, 15),
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ),
                    //firebase error message
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
                                    color:
                                        const Color.fromRGBO(255, 16, 15, 15),
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

                    //success message
                    Visibility(
                      visible: _isSuccess,
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
                                  'Account created successfully!',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        const Color.fromARGB(239, 0, 198, 89),
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    //sign up button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        onPressed: signUp,
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
                        child: !isLoading
                            ? Text(
                                'Sign Up',
                                style: GoogleFonts.roboto(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ),
                    ),

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

                    //google
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          UserCredential? userCredential =
                              await AuthService().signInWithGoogle(context);
                          print(userCredential?.user!.email);
                          setState(() {
                            isLoading = true;
                          });
                          await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(userCredential?.user!.email)
                              .set(
                            {
                              'name': userCredential?.user!.displayName,
                              'dob': null,
                              'gender': null,
                              'nic': null,
                              'address': null,
                              'mobile': null,
                            },
                          );
                          setState(() {
                            isLoading = false;
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
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Color.fromARGB(255, 7, 82, 96),
                          size: 20,
                        ),
                        label: !isLoading
                            ? Text(
                                'Sign up with Google',
                                style: GoogleFonts.roboto(
                                  fontSize: 20,
                                  color: const Color.fromARGB(255, 7, 82, 96),
                                ),
                              )
                            : const CircularProgressIndicator(
                                color: Color.fromARGB(255, 7, 82, 96),
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    //redirect to register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            color: const Color.fromARGB(255, 67, 63, 63),
                          ),
                        ),
                        ElevatedButton(
                      //
                       onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const SignIn();
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
                            'Sign In',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              // color: const Color.fromARGB(255, 7, 82, 96),
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

  // firebase error messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email already used. Go to Sign In page.';
      case 'operation-not-allowed':
        return 'Operation is not allowed.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'weak-password':
        return 'Enter a strong password.';
      case 'network-request-failed':
        return 'Network error.';
      default:
        return 'Account creation failed. Please try again';
    }
  }
}
