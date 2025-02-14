import 'dart:convert';
import 'dart:io';
import 'package:clout/components/datatextfield.dart';
import 'package:clout/components/primarybutton.dart';
import 'package:clout/defs/location.dart';
import 'package:clout/defs/user.dart';
import 'package:clout/main.dart';
import 'package:clout/models/searchlocation.dart';
import 'package:clout/models/unauthuserlistview.dart';
import 'package:clout/models/userlistview.dart';
import 'package:clout/screens/authentication/authscreen.dart';
import 'package:clout/screens/authentication/emailverificationscreen.dart';
import 'package:clout/services/db.dart';
import 'package:clout/services/logic.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart' as dp;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

class PicandNameScreen extends StatefulWidget {
  PicandNameScreen(
      {super.key, required this.analytics, required this.business});
  FirebaseAnalytics analytics;
  bool business;
  @override
  State<PicandNameScreen> createState() => _PicandNameScreenState();
}

class _PicandNameScreenState extends State<PicandNameScreen> {
  final fullnamecontroller = TextEditingController();
  ImagePicker picker = ImagePicker();
  var imagepath;
  db_conn db = db_conn();
  bool cancelbuttonpressed = false;
  bool continuebuttonpressed = false;
  applogic logic = applogic();
  File? compressedimgfile;
  TextEditingController cancelcontroller = TextEditingController();

  Future<File> CompressAndGetFile(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(".");
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 5,
      );

      //print(file.lengthSync());
      //print(result!.lengthSync());
      return File(result!.path);
    } catch (e) {
      throw Exception();
    }
  }

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void gousernamescreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => UsernameScreen(
                analytics: widget.analytics,
                business: widget.business,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "UsernameScreen")),
    );
  }

  void cancelsignupdialog(
      double screenheight, double screenwidth, String verificationId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Enter Code to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                          child: SizedBox(
                            width: screenwidth * 0.6,
                            child: Pinput(
                              length: 6,
                              pinAnimationType: PinAnimationType.slide,
                              showCursor: true,
                              focusedPinTheme: PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).primaryColor)),
                              defaultPinTheme: const PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color: Color.fromARGB(
                                              255, 151, 149, 149)),
                                    ),
                                  ),
                                  textStyle: TextStyle(fontSize: 25)),
                              onCompleted: (String verificationCode) async {
                                try {
                                  PhoneAuthCredential credential =
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: verificationCode);
                                  //link credential
                                  UserCredential usercredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                } catch (e) {
                                  logic.displayErrorSnackBar(
                                      "Make sure OTP code was inserted correctly.",
                                      context);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await db.firstcancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();
                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  void cancelsignupdialogbusiness(double screenheight, double screenwidth) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Enter Password to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                            child: textdatafield(screenwidth * 0.5,
                                "e.g. supersecret", cancelcontroller)),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                              email: FirebaseAuth
                                                  .instance.currentUser!.email!,
                                              password:
                                                  cancelcontroller.text.trim());
                                      await db.firstcancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();
                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    //print(imagepath == null);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: widget.business
              ? () async {
                  cancelsignupdialogbusiness(screenheight, screenwidth);
                }
              : () async {
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber,
                    verificationCompleted: (PhoneAuthCredential credential) {},
                    verificationFailed: (FirebaseAuthException e) {
                      logic.displayErrorSnackBar(
                          "Could not verify phone number", context);
                    },
                    codeSent: (String verificationId, int? resendToken) {
                      cancelsignupdialog(
                          screenheight, screenwidth, verificationId);
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {},
                  );
                },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "Who are you",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width: widget.business ? screenwidth / 3 : screenwidth * 0.25,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
                SizedBox(
                  width: widget.business
                      ? screenwidth * 2 / 3
                      : screenwidth * 0.75,
                  height: 4.0,
                )
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenheight * 0.1),
          const Center(
            child: Text(
              "Upload Profile Picture",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              textScaler: TextScaler.linear(1.0),
            ),
          ),
          SizedBox(
            height: screenheight * 0.03,
          ),
          Center(
              child: GestureDetector(
                  onTap: () async {
                    XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        imagepath = File(image.path);
                      });
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: imagepath != null
                        ? Image.file(
                            imagepath,
                            fit: BoxFit.cover,
                            height: screenheight * 0.2,
                            width: screenheight * 0.2,
                          )
                        : Container(
                            color: Theme.of(context).primaryColor,
                            height: screenheight * 0.2,
                            width: screenheight * 0.2,
                            child: Icon(
                              Icons.upload_rounded,
                              color: Colors.white,
                              size: screenheight * 0.18,
                            ),
                          ),
                  ))),
          SizedBox(height: screenheight * 0.05),
          textdatafield(screenwidth, "Full Name", fullnamecontroller),
          SizedBox(
            height: screenheight * 0.1,
          ),
          GestureDetector(
            onTap: continuebuttonpressed
                ? null
                : () async {
                    setState(() {
                      continuebuttonpressed = true;
                    });
                    bool compressedimgpathgood = false;
                    if (imagepath != null &&
                        fullnamecontroller.text.trim().isNotEmpty) {
                      try {
                        compressedimgfile = await CompressAndGetFile(imagepath);
                        setState(() {
                          compressedimgpathgood = true;
                        });
                      } catch (e) {
                        logic.displayErrorSnackBar(
                            "Error with profile picture, might be an invalid format",
                            context);
                      }
                      if (compressedimgpathgood) {
                        try {
                          await db.changepfp(compressedimgfile!,
                              FirebaseAuth.instance.currentUser!.uid);
                          await db.changeattribute(
                              'fullname',
                              fullnamecontroller.text.trim(),
                              FirebaseAuth.instance.currentUser!.uid);
                          await db.changeattributebool('setnameandpfp', true,
                              FirebaseAuth.instance.currentUser!.uid);
                          gousernamescreen();
                        } catch (e) {
                          print(e);
                          logic.displayErrorSnackBar(
                              "Could not proceed with signup, please check internet connection and try again",
                              context);
                        }
                      }
                    } else if (imagepath == null) {
                      logic.displayErrorSnackBar(
                          "Please upload Profile Picture", context);
                    } else if (fullnamecontroller.text.trim().isEmpty) {
                      logic.displayErrorSnackBar(
                          "Please enter your full name", context);
                    } else {
                      logic.displayErrorSnackBar(
                          "Error with full name or profile picture", context);
                    }

                    setState(() {
                      continuebuttonpressed = false;
                    });
                  },
            child: PrimaryButton(
              screenwidth: screenwidth,
              buttonpressed: continuebuttonpressed,
              text: "Continue",
              buttonwidth: screenwidth * 0.6,
              bold: false,
            ),
          )
        ],
      )),
    );
  }
}

class UsernameScreen extends StatefulWidget {
  UsernameScreen({Key? key, required this.analytics, required this.business})
      : super(key: key);
  FirebaseAnalytics analytics;
  bool business;
  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final usernamecontroller = TextEditingController();
  db_conn db = db_conn();
  bool cancelbuttonpressed = false;
  bool continuebuttonpressed = false;
  applogic logic = applogic();
  TextEditingController cancelcontroller = TextEditingController();

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void gotomiscscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => MiscScreen(
                analytics: widget.analytics,
              ),
          settings: const RouteSettings(name: "MiscScreen")),
    );
  }

  void gotobusinessmiscscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => BusinessMiscScreen(
                analytics: widget.analytics,
              ),
          settings: const RouteSettings(name: "BusinessMiscScreen")),
    );
  }

  void cancelsignupdialog(
      double screenheight, double screenwidth, String verificationId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Enter Code to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                          child: SizedBox(
                            width: screenwidth * 0.6,
                            child: Pinput(
                              length: 6,
                              pinAnimationType: PinAnimationType.slide,
                              showCursor: true,
                              focusedPinTheme: PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).primaryColor)),
                              defaultPinTheme: const PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color: Color.fromARGB(
                                              255, 151, 149, 149)),
                                    ),
                                  ),
                                  textStyle: TextStyle(fontSize: 25)),
                              onCompleted: (String verificationCode) async {
                                try {
                                  PhoneAuthCredential credential =
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: verificationCode);
                                  //link credential
                                  UserCredential usercredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                } catch (e) {
                                  logic.displayErrorSnackBar(
                                      "Make sure OTP code was inserted correctly.",
                                      context);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await db.cancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();

                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  void cancelsignupdialogbusiness(double screenheight, double screenwidth) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Enter Password to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                            child: textdatafield(screenwidth * 0.5,
                                "e.g. supersecret", cancelcontroller)),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                              email: FirebaseAuth
                                                  .instance.currentUser!.email!,
                                              password:
                                                  cancelcontroller.text.trim());
                                      await db.cancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();
                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: widget.business
              ? () async {
                  cancelsignupdialogbusiness(screenheight, screenwidth);
                }
              : () async {
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber,
                    verificationCompleted: (PhoneAuthCredential credential) {},
                    verificationFailed: (FirebaseAuthException e) {
                      logic.displayErrorSnackBar(
                          "Could not verify phone number", context);
                    },
                    codeSent: (String verificationId, int? resendToken) {
                      cancelsignupdialog(
                          screenheight, screenwidth, verificationId);
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {},
                  );
                },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "Username",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width:
                      widget.business ? screenwidth * 2 / 3 : screenwidth * 0.5,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
                SizedBox(
                  width: widget.business ? screenwidth / 3 : screenwidth * 0.5,
                  height: 4.0,
                )
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: screenheight * 0.3),
          textdatafield(screenwidth, "Username", usernamecontroller),
          SizedBox(
            height: screenheight * 0.1,
          ),
          GestureDetector(
            onTap: continuebuttonpressed
                ? null
                : () async {
                    setState(() {
                      continuebuttonpressed = true;
                    });
                    bool uniqueness = await db.usernameUnique(
                        usernamecontroller.text.trim().toLowerCase());
                    if (!uniqueness &&
                        usernamecontroller.text.trim().isNotEmpty) {
                      setState(() {
                        logic.displayErrorSnackBar(
                            "Username already taken", context);
                      });
                    } else if (usernamecontroller.text.trim().isEmpty) {
                      logic.displayErrorSnackBar("Invalid Username", context);
                    } else if (!RegExp(r'^[a-zA-Z0-9&%=]+$')
                        .hasMatch(usernamecontroller.text.trim())) {
                      logic.displayErrorSnackBar(
                          "Please only enter alphanumeric characters", context);
                    } else {
                      try {
                        await db.changeusername(
                            usernamecontroller.text.trim().toLowerCase(),
                            FirebaseAuth.instance.currentUser!.uid);
                        await db.changeattributebool('setusername', true,
                            FirebaseAuth.instance.currentUser!.uid);
                        widget.business
                            ? gotobusinessmiscscreen()
                            : gotomiscscreen();
                      } catch (e) {
                        logic.displayErrorSnackBar(
                            "Could not proceed with signup, please check internet connection and try again",
                            context);
                      }
                    }
                    setState(() {
                      continuebuttonpressed = false;
                    });
                  },
            child: PrimaryButton(
                screenwidth: screenwidth,
                buttonpressed: continuebuttonpressed,
                text: "Continue",
                buttonwidth: screenwidth * 0.6,
                bold: false),
          )
        ],
      )),
    );
  }
}

class MiscScreen extends StatefulWidget {
  MiscScreen({super.key, required this.analytics});
  FirebaseAnalytics analytics;
  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  DateTime birthday = DateTime(0, 0, 0);
  String gender = 'Male';
  String nationality = 'Australia';
  db_conn db = db_conn();
  bool cancelbuttonpressed = false;
  bool continuebuttonpressed = false;
  applogic logic = applogic();

  var maskFormatter = MaskTextInputFormatter(
      mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  var genders = ['Male', 'Female', 'Non-Binary'];
  var nations = [
    'Afghanistan',
    'Aland Islands',
    'Albania',
    'Algeria',
    'American Samoa',
    'Andorra',
    'Angola',
    'Anguilla',
    'Antarctica',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Aruba',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bermuda',
    'Bhutan',
    'Bolivia, Plurinational State of',
    'Bonaire, Sint Eustatius and Saba',
    'Bosnia and Herzegovina',
    'Botswana',
    'Bouvet Island',
    'Brazil',
    'British Indian Ocean Territory',
    'Brunei Darussalam',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Cayman Islands',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Christmas Island',
    'Cocos (Keeling) Islands',
    'Colombia',
    'Comoros',
    'Congo',
    'Congo, The Democratic Republic of the',
    'Cook Islands',
    'Costa Rica',
    "Côte d'Ivoire",
    'Croatia',
    'Cuba',
    'Curaçao',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Falkland Islands (Malvinas)',
    'Faroe Islands',
    'Fiji',
    'Finland',
    'France',
    'French Guiana',
    'French Polynesia',
    'French Southern Territories',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Gibraltar',
    'Greece',
    'Greenland',
    'Grenada',
    'Guadeloupe',
    'Guam',
    'Guatemala',
    'Guernsey',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Heard Island and McDonald Islands',
    'Holy See (Vatican City State)',
    'Honduras',
    'Hong Kong',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran, Islamic Republic of',
    'Iraq',
    'Ireland',
    'Isle of Man',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jersey',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    "Korea, Democratic People's Republic of",
    'Korea, Republic of',
    'Kuwait',
    'Kyrgyzstan',
    "Lao People's Democratic Republic",
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macao',
    'Macedonia, Republic of',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Martinique',
    'Mauritania',
    'Mauritius',
    'Mayotte',
    'Mexico',
    'Micronesia, Federated States of',
    'Moldova, Republic of',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Montserrat',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Caledonia',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Niue',
    'Norfolk Island',
    'Northern Mariana Islands',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestinian Territory, Occupied',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Pitcairn',
    'Poland',
    'Portugal',
    'Puerto Rico',
    'Qatar',
    'Réunion',
    'Romania',
    'Russian Federation',
    'Rwanda',
    'Saint Barthélemy',
    'Saint Helena, Ascension and Tristan da Cunha',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Martin (French part)',
    'Saint Pierre and Miquelon',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Sint Maarten (Dutch part)',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Georgia and the South Sandwich Islands',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'South Sudan',
    'Svalbard and Jan Mayen',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syrian Arab Republic',
    'Taiwan, Province of China',
    'Tajikistan',
    'Tanzania, United Republic of',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tokelau',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Turks and Caicos Islands',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'United States Minor Outlying Islands',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Venezuela, Bolivarian Republic of',
    'Viet Nam',
    'Virgin Islands, British',
    'Virgin Islands, U.S.',
    'Wallis and Futuna',
    'Yemen',
    'Zambia',
    'Zimbabwe'
  ];

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void gointerestscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => InterestScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "InterestScreen")),
    );
  }

  void cancelsignupdialog(
      double screenheight, double screenwidth, String verificationId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Enter Code to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                          child: SizedBox(
                            width: screenwidth * 0.6,
                            child: Pinput(
                              length: 6,
                              pinAnimationType: PinAnimationType.slide,
                              showCursor: true,
                              focusedPinTheme: PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).primaryColor)),
                              defaultPinTheme: const PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color: Color.fromARGB(
                                              255, 151, 149, 149)),
                                    ),
                                  ),
                                  textStyle: TextStyle(fontSize: 25)),
                              onCompleted: (String verificationCode) async {
                                try {
                                  PhoneAuthCredential credential =
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: verificationCode);
                                  //link credential
                                  UserCredential usercredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                } catch (e) {
                                  logic.displayErrorSnackBar(
                                      "Make sure OTP code was inserted correctly.",
                                      context);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await db.cancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();

                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.verifyPhoneNumber(
              phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber,
              verificationCompleted: (PhoneAuthCredential credential) {},
              verificationFailed: (FirebaseAuthException e) {
                logic.displayErrorSnackBar(
                    "Could not verify phone number", context);
              },
              codeSent: (String verificationId, int? resendToken) {
                cancelsignupdialog(screenheight, screenwidth, verificationId);
              },
              codeAutoRetrievalTimeout: (String verificationId) {},
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "Other info",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width: screenwidth * 0.75,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
                SizedBox(
                  width: screenwidth * 0.25,
                  height: 4.0,
                )
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: screenheight * 0.2),
            SizedBox(
              width: screenwidth * 0.6,
              child: DropdownButtonFormField(
                borderRadius: BorderRadius.circular(20),
                decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor))),
                value: gender,
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                onSaved: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                items: genders.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: screenheight * 0.02),
            SizedBox(
              width: screenwidth * 0.6,
              child: DropdownButtonFormField(
                borderRadius: BorderRadius.circular(20),
                decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                )),
                value: nationality,
                onChanged: (String? newValue) {
                  setState(() {
                    nationality = newValue!;
                  });
                },
                onSaved: (String? newValue) {
                  setState(() {
                    nationality = newValue!;
                  });
                },
                items: nations.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            SizedBox(height: screenheight * 0.02),
            GestureDetector(
              onTap: () {
                dp.DatePicker.showDatePicker(
                  context,
                  showTitleActions: true,
                  minTime: DateTime(1950, 1, 1),
                  maxTime: DateTime(DateTime.now().year - 18,
                      DateTime.now().month, DateTime.now().day),
                  currentTime: DateTime(DateTime.now().year - 18,
                      DateTime.now().month, DateTime.now().day),
                  onChanged: (date) {
                    setState(() {
                      birthday = date;
                    });
                  },
                  onConfirm: (date) {
                    setState(() {
                      birthday = date;
                    });
                  },
                );
              },
              child: Container(
                height: screenwidth * 0.13,
                width: screenwidth * 0.6,
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    birthday == DateTime(0, 0, 0)
                        ? "Enter birthday"
                        : DateFormat('dd MMMM yyyy').format(birthday),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const Icon(
                    Icons.date_range,
                    size: 15,
                  )
                ]),
              ),
            ),
            SizedBox(
              height: screenheight * 0.1,
            ),
            GestureDetector(
              onTap: continuebuttonpressed
                  ? null
                  : () async {
                      setState(() {
                        continuebuttonpressed = true;
                      });

                      if (birthday != DateTime(0, 0, 0)) {
                        try {
                          await db.changeattribute('gender', gender,
                              FirebaseAuth.instance.currentUser!.uid);
                          await db.changeattribute('nationality', nationality,
                              FirebaseAuth.instance.currentUser!.uid);
                          await db.changebirthday(
                              birthday, FirebaseAuth.instance.currentUser!.uid);
                          await db.changeattributebool('setmisc', true,
                              FirebaseAuth.instance.currentUser!.uid);
                          gointerestscreen();
                        } catch (e) {
                          logic.displayErrorSnackBar(
                              "Could not proceed with signup, please check internet connection and try again",
                              context);
                        }
                      } else {
                        logic.displayErrorSnackBar(
                            "Please try again and make sure all fields are filled correctly",
                            context);
                      }
                      setState(() {
                        continuebuttonpressed = false;
                      });
                    },
              child: PrimaryButton(
                screenwidth: screenwidth,
                buttonpressed: continuebuttonpressed,
                text: "Continue",
                buttonwidth: screenwidth * 0.6,
                bold: false,
              ),
            )
          ],
        ),
      )),
    );
  }
}

class BusinessMiscScreen extends StatefulWidget {
  BusinessMiscScreen({super.key, required this.analytics});
  FirebaseAnalytics analytics;
  @override
  State<BusinessMiscScreen> createState() => _BusinessMiscScreenState();
}

class _BusinessMiscScreenState extends State<BusinessMiscScreen> {
  db_conn db = db_conn();
  bool cancelbuttonpressed = false;
  bool continuebuttonpressed = false;
  applogic logic = applogic();
  TextEditingController cancelcontroller = TextEditingController();
  bool emptylocation = true;
  List LatLngs = [];
  AppLocation chosenLocation =
      AppLocation(address: "", city: "", country: "", center: [0.0, 0.0]);
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController? mapController;
  List<String> allinterests = [
    "Sports",
    "Nature",
    "Music",
    "Dance",
    "Movies",
    "Acting",
    "Singing",
    "Drinking",
    "Food",
    "Art",
    "Animals",
    "Fashion",
    "Cooking",
    "Culture",
    "Travel",
    "Games",
    "Studying",
    "Chilling"
  ];
  String interest = "Sports";

  void checklocationempty() {
    if (chosenLocation.address == "" &&
        chosenLocation.city == "" &&
        chosenLocation.country == "" &&
        listEquals(chosenLocation.center, [0.0, 0.0])) {
      setState(() {
        emptylocation = true;
      });
    } else {
      setState(() {
        emptylocation = false;
      });
    }
  }

  Future _addMarker(LatLng latlang) async {
    setState(() {
      final MarkerId markerId = MarkerId("chosenlocation");
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position:
            latlang, //With this parameter you automatically obtain latitude and longitude
        infoWindow: const InfoWindow(
          title: "Chosen Location",
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      markers[markerId] = marker;
    });

    //This is optional, it will zoom when the marker has been created
  }

  void donesignup() async {
    await db.setdonesignuptime(FirebaseAuth.instance.currentUser!.uid);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => EmailVerificationScreen(
                analytics: widget.analytics,
              ),
          settings: const RouteSettings(name: "EmailVerificationScreen"),
          fullscreenDialog: true),
    );
  }

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void cancelsignupdialogbusiness(double screenheight, double screenwidth) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Enter Password to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                            child: textdatafield(screenwidth * 0.5,
                                "e.g. supersecret", cancelcontroller)),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                              email: FirebaseAuth
                                                  .instance.currentUser!.email!,
                                              password:
                                                  cancelcontroller.text.trim());
                                      await db.cancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();
                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () async {
            cancelsignupdialogbusiness(screenheight, screenwidth);
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "Other info",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width: screenwidth * 0.75,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
                SizedBox(
                  width: screenwidth * 0.25,
                  height: 4.0,
                )
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: screenheight * 0.15,
            ),
            const Text(
              "Choose your\nbusiness category",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(1.0),
            ),
            SizedBox(
              height: screenheight * 0.01,
            ),
            SizedBox(
              width: screenwidth * 0.6,
              child: DropdownButtonFormField(
                borderRadius: BorderRadius.circular(20),
                decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor))),
                value: interest,
                onChanged: (String? newValue) {
                  setState(() {
                    interest = newValue!;
                  });
                },
                onSaved: (String? newValue) {
                  setState(() {
                    interest = newValue!;
                  });
                },
                items: allinterests.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            SizedBox(
              height: screenheight * 0.05,
            ),
            GestureDetector(
              onTap: () async {
                Position _locationData = await Geolocator.getCurrentPosition();
                setState(() {
                  LatLngs = [_locationData.latitude, _locationData.longitude];
                });
                AppLocation chosen = emptylocation
                    ? await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SearchLocation(
                                  locationchosen: false,
                                  startlocation: AppLocation(
                                      address: "",
                                      center: [0.0, 0.0],
                                      city: "",
                                      country: ""),
                                  curruserLatLng: LatLngs,
                                  isbusiness: true,
                                ),
                            settings:
                                const RouteSettings(name: "SearchLocation")))
                    : await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SearchLocation(
                                  locationchosen: true,
                                  startlocation: AppLocation(
                                    address: chosenLocation.address,
                                    center: chosenLocation.center,
                                    city: chosenLocation.city,
                                    country: chosenLocation.country,
                                  ),
                                  isbusiness: true,
                                  curruserLatLng: LatLngs,
                                ),
                            settings: RouteSettings(name: "SearchLocation")));
                setState(() {
                  chosenLocation = chosen;
                });
                _addMarker(
                    LatLng(chosenLocation.center[0], chosenLocation.center[1]));
                mapController?.moveCamera(CameraUpdate.newLatLngZoom(
                    LatLng(chosenLocation.center[0], chosenLocation.center[1]),
                    17.0));
                checklocationempty();
              },
              child: Container(
                height: screenwidth * 0.13,
                width: screenwidth * 0.6,
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(20)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    emptylocation ? "Set Business Location" : "Change Location",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    textScaler: TextScaler.linear(1.0),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  const Icon(
                    Icons.map_rounded,
                    size: 15,
                  )
                ]),
              ),
            ),
            SizedBox(
              height: screenheight * 0.02,
            ),
            emptylocation
                ? const SizedBox()
                : SizedBox(
                    height: screenheight * 0.2,
                    width: screenwidth * 0.6,
                    child: GoogleMap(
                      //Map widget from google_maps_flutter package
                      myLocationButtonEnabled: false,
                      zoomGesturesEnabled: true, //enable Zoom in, out on map
                      initialCameraPosition: CameraPosition(
                        //innital position in map
                        target: LatLng(chosenLocation.center[0],
                            chosenLocation.center[1]), //initial position
                        zoom: 14.0, //initial zoom level
                      ),
                      mapType: MapType.normal, //map type
                      markers: Set<Marker>.of(markers.values),
                      onMapCreated: (controller) {
                        //method called when map is created
                        setState(() {
                          mapController = controller;
                        });
                      },
                    ),
                  ),
            SizedBox(
              height: !emptylocation ? screenheight * 0.1 : screenheight * 0.3,
            ),
            GestureDetector(
              onTap: continuebuttonpressed
                  ? null
                  : () async {
                      setState(() {
                        continuebuttonpressed = true;
                      });
                      if (!emptylocation) {
                        try {
                          await db.changeinterests('interests', [interest],
                              FirebaseAuth.instance.currentUser!.uid);
                          await db.businesssetloc(
                              FirebaseAuth.instance.currentUser!.uid,
                              chosenLocation);
                          await db.changeattributebool('setmisc', true,
                              FirebaseAuth.instance.currentUser!.uid);
                          donesignup();
                        } catch (e) {
                          logic.displayErrorSnackBar(
                              "An error occured, please try again.", context);
                        }
                      } else {
                        logic.displayErrorSnackBar(
                            "Please enter a valid location for your business.",
                            context);
                      }
                      setState(() {
                        continuebuttonpressed = false;
                      });
                    },
              child: PrimaryButton(
                screenwidth: screenwidth,
                buttonpressed: continuebuttonpressed,
                text: "Continue",
                buttonwidth: screenwidth * 0.6,
                bold: false,
              ),
            )
          ],
        ),
      )),
    );
  }
}

class InterestScreen extends StatefulWidget {
  InterestScreen({Key? key, required this.analytics}) : super(key: key);
  FirebaseAnalytics analytics;
  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  List allinterests = [
    "Sports",
    "Nature",
    "Music",
    "Dance",
    "Movies",
    "Acting",
    "Singing",
    "Drinking",
    "Food",
    "Art",
    "Animals",
    "Fashion",
    "Cooking",
    "Culture",
    "Travel",
    "Games",
    "Studying",
    "Chilling"
  ];
  List<Color> textcolors =
      List.filled(10, const Color.fromARGB(255, 255, 48, 117));
  List<Color> cardcolors = List.filled(10, Colors.white);
  List selectedinterests = [];
  db_conn db = db_conn();
  bool buttonpressed = false;
  bool cancelbuttonpressed = false;
  applogic logic = applogic();

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void donesignup() async {
    await db.setdonesignuptime(FirebaseAuth.instance.currentUser!.uid);
    AppUser curruser =
        await db.getUserFromUID(FirebaseAuth.instance.currentUser!.uid);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => FriendsContactScreen(
                analytics: widget.analytics,
                curruser: curruser,
                loggedin: false,
              ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: "FriendsContactScreen")),
    );
  }

  void cancelsignupdialog(
      double screenheight, double screenwidth, String verificationId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Enter Code to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                          child: SizedBox(
                            width: screenwidth * 0.6,
                            child: Pinput(
                              length: 6,
                              pinAnimationType: PinAnimationType.slide,
                              showCursor: true,
                              focusedPinTheme: PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).primaryColor)),
                              defaultPinTheme: const PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color: Color.fromARGB(
                                              255, 151, 149, 149)),
                                    ),
                                  ),
                                  textStyle: TextStyle(fontSize: 25)),
                              onCompleted: (String verificationCode) async {
                                try {
                                  PhoneAuthCredential credential =
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: verificationCode);
                                  //link credential
                                  UserCredential usercredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                } catch (e) {
                                  logic.displayErrorSnackBar(
                                      "Make sure OTP code was inserted correctly.",
                                      context);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      await db.cancelsignup(FirebaseAuth
                                          .instance.currentUser!.uid);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();

                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  Widget _listviewitem(String interest) {
    return GestureDetector(
      onTap: () {
        if (selectedinterests.contains(interest)) {
          setState(() {
            selectedinterests.removeWhere((element) => element == interest);
          });
        } else {
          setState(() {
            selectedinterests.add(interest);
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(
              width: selectedinterests.contains(interest) ? 2 : 0,
              color: selectedinterests.contains(interest)
                  ? Theme.of(context).primaryColor
                  : Colors.black),
          image: DecorationImage(
              opacity: selectedinterests.contains(interest) ? 0.8 : 1,
              image: AssetImage(
                "assets/images/interestbanners/${interest.toLowerCase()}.jpeg",
              ),
              fit: BoxFit.cover),
        ),
        child: Center(
            child: Text(
          interest,
          style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.bold,
              color: selectedinterests.contains(interest)
                  ? Theme.of(context).primaryColor
                  : Colors.white),
          textScaler: TextScaler.linear(1.0),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.verifyPhoneNumber(
              phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber,
              verificationCompleted: (PhoneAuthCredential credential) {},
              verificationFailed: (FirebaseAuthException e) {
                logic.displayErrorSnackBar(
                    "Could not verify phone number", context);
              },
              codeSent: (String verificationId, int? resendToken) {
                cancelsignupdialog(screenheight, screenwidth, verificationId);
              },
              codeAutoRetrievalTimeout: (String verificationId) {},
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "What are your interests?",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width: screenwidth,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
              ],
            )),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
        child: Stack(children: [
          Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  shrinkWrap: true,
                  itemCount: allinterests.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: _listviewitem(allinterests[index]),
                    );
                  }),
                ),
              ),
            ],
          ),
        ]),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: buttonpressed
              ? null
              : () async {
                  setState(() {
                    buttonpressed = true;
                  });
                  try {
                    if (selectedinterests.length >= 3) {
                      await db.changeinterests('interests', selectedinterests,
                          FirebaseAuth.instance.currentUser!.uid);
                      await db.changeattributebool('setinterests', true,
                          FirebaseAuth.instance.currentUser!.uid);
                      await widget.analytics.setUserId(
                          id: FirebaseAuth.instance.currentUser!.uid);
                      await widget.analytics.logSignUp(signUpMethod: "email");
                      donesignup();
                    } else {
                      logic.displayErrorSnackBar(
                          "Choose at least 3 interests", context);
                      setState(() {
                        buttonpressed = false;
                      });
                    }
                  } catch (e) {
                    logic.displayErrorSnackBar(
                        "Could not create user", context);
                    setState(() {
                      buttonpressed = false;
                    });
                  }
                },
          backgroundColor: Theme.of(context).primaryColor,
          child: buttonpressed
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SpinKitThreeInOut(
                    color: Colors.white,
                    size: 12,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 30,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class WebFinishScreen extends StatefulWidget {
  WebFinishScreen({super.key, required this.analytics});
  FirebaseAnalytics analytics;
  @override
  State<WebFinishScreen> createState() => _WebFinishScreenState();
}

class _WebFinishScreenState extends State<WebFinishScreen> {
  String gender = 'Male';
  String nationality = 'Australia';
  db_conn db = db_conn();
  bool cancelbuttonpressed = false;
  bool continuebuttonpressed = false;
  applogic logic = applogic();
  ImagePicker picker = ImagePicker();
  var imagepath;
  File? compressedimgfile;

  var genders = ['Male', 'Female', 'Non-Binary'];
  var nations = [
    'Afghanistan',
    'Aland Islands',
    'Albania',
    'Algeria',
    'American Samoa',
    'Andorra',
    'Angola',
    'Anguilla',
    'Antarctica',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Aruba',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bermuda',
    'Bhutan',
    'Bolivia, Plurinational State of',
    'Bonaire, Sint Eustatius and Saba',
    'Bosnia and Herzegovina',
    'Botswana',
    'Bouvet Island',
    'Brazil',
    'British Indian Ocean Territory',
    'Brunei Darussalam',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Cayman Islands',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Christmas Island',
    'Cocos (Keeling) Islands',
    'Colombia',
    'Comoros',
    'Congo',
    'Congo, The Democratic Republic of the',
    'Cook Islands',
    'Costa Rica',
    "Côte d'Ivoire",
    'Croatia',
    'Cuba',
    'Curaçao',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Falkland Islands (Malvinas)',
    'Faroe Islands',
    'Fiji',
    'Finland',
    'France',
    'French Guiana',
    'French Polynesia',
    'French Southern Territories',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Gibraltar',
    'Greece',
    'Greenland',
    'Grenada',
    'Guadeloupe',
    'Guam',
    'Guatemala',
    'Guernsey',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Heard Island and McDonald Islands',
    'Holy See (Vatican City State)',
    'Honduras',
    'Hong Kong',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran, Islamic Republic of',
    'Iraq',
    'Ireland',
    'Isle of Man',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jersey',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    "Korea, Democratic People's Republic of",
    'Korea, Republic of',
    'Kuwait',
    'Kyrgyzstan',
    "Lao People's Democratic Republic",
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macao',
    'Macedonia, Republic of',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Martinique',
    'Mauritania',
    'Mauritius',
    'Mayotte',
    'Mexico',
    'Micronesia, Federated States of',
    'Moldova, Republic of',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Montserrat',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Caledonia',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Niue',
    'Norfolk Island',
    'Northern Mariana Islands',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestinian Territory, Occupied',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Pitcairn',
    'Poland',
    'Portugal',
    'Puerto Rico',
    'Qatar',
    'Réunion',
    'Romania',
    'Russian Federation',
    'Rwanda',
    'Saint Barthélemy',
    'Saint Helena, Ascension and Tristan da Cunha',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Martin (French part)',
    'Saint Pierre and Miquelon',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Sint Maarten (Dutch part)',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Georgia and the South Sandwich Islands',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'South Sudan',
    'Svalbard and Jan Mayen',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syrian Arab Republic',
    'Taiwan, Province of China',
    'Tajikistan',
    'Tanzania, United Republic of',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tokelau',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Turks and Caicos Islands',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'United States Minor Outlying Islands',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Venezuela, Bolivarian Republic of',
    'Viet Nam',
    'Virgin Islands, British',
    'Virgin Islands, U.S.',
    'Wallis and Futuna',
    'Yemen',
    'Zambia',
    'Zimbabwe'
  ];

  Future<File> CompressAndGetFile(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(".");
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";
      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 5,
      );

      //print(file.lengthSync());
      //print(result!.lengthSync());
      return File(result!.path);
    } catch (e) {
      throw Exception();
    }
  }

  void goauthscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "AuthScreen")),
    );
  }

  void gointerestscreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => InterestScreen(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: RouteSettings(name: "InterestScreen")),
    );
  }

  void cancelsignupdialog(
      double screenheight, double screenwidth, String verificationId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  height: screenheight * 0.3,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Enter Code to Cancel",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        SizedBox(
                          height: screenheight * 0.02,
                        ),
                        Center(
                          child: SizedBox(
                            width: screenwidth * 0.6,
                            child: Pinput(
                              length: 6,
                              pinAnimationType: PinAnimationType.slide,
                              showCursor: true,
                              focusedPinTheme: PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  textStyle: TextStyle(
                                      fontSize: 25,
                                      color: Theme.of(context).primaryColor)),
                              defaultPinTheme: const PinTheme(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                          width: 1.5,
                                          color: Color.fromARGB(
                                              255, 151, 149, 149)),
                                    ),
                                  ),
                                  textStyle: TextStyle(fontSize: 25)),
                              onCompleted: (String verificationCode) async {
                                try {
                                  PhoneAuthCredential credential =
                                      PhoneAuthProvider.credential(
                                          verificationId: verificationId,
                                          smsCode: verificationCode);
                                  //link credential
                                  UserCredential usercredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                } catch (e) {
                                  logic.displayErrorSnackBar(
                                      "Make sure OTP code was inserted correctly.",
                                      context);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenheight * 0.05,
                        ),
                        GestureDetector(
                            onTap: cancelbuttonpressed
                                ? null
                                : () async {
                                    setState(() {
                                      cancelbuttonpressed = true;
                                    });
                                    try {
                                      AppUser curruser =
                                          await db.getUserFromUID(FirebaseAuth
                                              .instance.currentUser!.uid);
                                      await db.deletewebuser(curruser);
                                      await FirebaseAuth.instance.currentUser!
                                          .delete();
                                      goauthscreen();
                                    } catch (e) {
                                      logic.displayErrorSnackBar(
                                          "Could not cancel signup", context);
                                    } finally {
                                      setState(() {
                                        cancelbuttonpressed = false;
                                      });
                                    }
                                  },
                            child: PrimaryButton(
                                screenwidth: screenwidth,
                                buttonpressed: cancelbuttonpressed,
                                text: "Cancel Sign Up",
                                buttonwidth: screenwidth * 0.5,
                                bold: false)),
                      ]),
                ),
              );
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.verifyPhoneNumber(
              phoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber,
              verificationCompleted: (PhoneAuthCredential credential) {},
              verificationFailed: (FirebaseAuthException e) {
                logic.displayErrorSnackBar(
                    "Could not verify phone number", context);
              },
              codeSent: (String verificationId, int? resendToken) {
                cancelsignupdialog(screenheight, screenwidth, verificationId);
              },
              codeAutoRetrievalTimeout: (String verificationId) {},
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          "Finish Signup",
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 30),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Row(
              children: [
                Container(
                  width: screenwidth * 0.5,
                  color: Theme.of(context).primaryColor,
                  height: 4.0,
                ),
                SizedBox(
                  width: screenwidth * 0.5,
                  height: 4.0,
                )
              ],
            )),
      ),
      body: SingleChildScrollView(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenheight * 0.1),
            const Center(
              child: Text(
                "Upload Profile Picture",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                textScaler: TextScaler.linear(1.0),
              ),
            ),
            SizedBox(
              height: screenheight * 0.03,
            ),
            Center(
                child: GestureDetector(
                    onTap: () async {
                      XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          imagepath = File(image.path);
                        });
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: imagepath != null
                          ? Image.file(
                              imagepath,
                              fit: BoxFit.cover,
                              height: screenheight * 0.2,
                              width: screenheight * 0.2,
                            )
                          : Container(
                              color: Theme.of(context).primaryColor,
                              height: screenheight * 0.2,
                              width: screenheight * 0.2,
                              child: Icon(
                                Icons.upload_rounded,
                                color: Colors.white,
                                size: screenheight * 0.18,
                              ),
                            ),
                    ))),
            SizedBox(height: screenheight * 0.05),
            SizedBox(
              width: screenwidth * 0.6,
              child: DropdownButtonFormField(
                borderRadius: BorderRadius.circular(20),
                decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor))),
                value: gender,
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                onSaved: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                items: genders.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: screenheight * 0.02),
            SizedBox(
              width: screenwidth * 0.6,
              child: DropdownButtonFormField(
                borderRadius: BorderRadius.circular(20),
                decoration: InputDecoration(
                    focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                )),
                value: nationality,
                onChanged: (String? newValue) {
                  setState(() {
                    nationality = newValue!;
                  });
                },
                onSaved: (String? newValue) {
                  setState(() {
                    nationality = newValue!;
                  });
                },
                items: nations.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            SizedBox(
              height: screenheight * 0.1,
            ),
            GestureDetector(
              onTap: continuebuttonpressed
                  ? null
                  : () async {
                      setState(() {
                        continuebuttonpressed = true;
                      });
                      bool compressedimgpathgood = false;
                      if (imagepath != null) {
                        try {
                          compressedimgfile =
                              await CompressAndGetFile(imagepath);
                          setState(() {
                            compressedimgpathgood = true;
                          });
                        } catch (e) {
                          logic.displayErrorSnackBar(
                              "Error with profile picture, might be an invalid format",
                              context);
                        }
                        if (compressedimgpathgood) {
                          try {
                            await db.changepfp(compressedimgfile!,
                                FirebaseAuth.instance.currentUser!.uid);
                            await db.changeattribute('gender', gender,
                                FirebaseAuth.instance.currentUser!.uid);
                            await db.changeattribute('nationality', nationality,
                                FirebaseAuth.instance.currentUser!.uid);
                            await db.changeattributebool('incompletewebsignup',
                                false, FirebaseAuth.instance.currentUser!.uid);
                            gointerestscreen();
                          } catch (e) {
                            logic.displayErrorSnackBar(
                                "Could not proceed with signup, please check internet connection and try again",
                                context);
                          }
                        }
                      } else {
                        logic.displayErrorSnackBar(
                            "Please upload Profile Picture", context);
                      }
                      setState(() {
                        continuebuttonpressed = false;
                      });
                    },
              child: PrimaryButton(
                screenwidth: screenwidth,
                buttonpressed: continuebuttonpressed,
                text: "Continue",
                buttonwidth: screenwidth * 0.6,
                bold: false,
              ),
            )
          ],
        ),
      )),
    );
  }
}

class FriendsContactScreen extends StatefulWidget {
  FriendsContactScreen(
      {super.key,
      required this.analytics,
      required this.curruser,
      required this.loggedin});
  FirebaseAnalytics analytics;
  AppUser curruser;
  bool loggedin;
  @override
  State<FriendsContactScreen> createState() => _FriendsContactScreenState();
}

class _FriendsContactScreenState extends State<FriendsContactScreen> {
  bool showcontacts = false;
  bool loading = false;
  db_conn db = db_conn();
  applogic logic = applogic();
  List<AppUser> friends = [];

  Map<String, int> prefixes = {
    'SK': 421,
    'KI': 686,
    'LV': 371,
    'GH': 233,
    'JP': 81,
    'SA': 966,
    'TD': 235,
    'SX': 1,
    'CY': 357,
    'CH': 41,
    'EG': 20,
    'PA': 507,
    'KP': 850,
    'CO': 57,
    'GW': 245,
    'KG': 996,
    'AW': 297,
    'FM': 691,
    'SB': 677,
    'HR': 385,
    'PY': 595,
    'BG': 359,
    'IQ': 964,
    'ID': 62,
    'GQ': 240,
    'CA': 1,
    'CG': 242,
    'MO': 853,
    'SL': 232,
    'LA': 856,
    'OM': 968,
    'MP': 1,
    'DK': 45,
    'FI': 358,
    'DO': 1,
    'BM': 1,
    'GN': 224,
    'NE': 227,
    'ER': 291,
    'DE': 49,
    'UM': 0,
    'CM': 237,
    'PR': 1,
    'RO': 40,
    'AZ': 994,
    'DZ': 213,
    'BW': 267,
    'MK': 389,
    'HN': 504,
    'IS': 354,
    'SJ': 47,
    'ME': 382,
    'NR': 674,
    'AD': 376,
    'BY': 375,
    'RE': 262,
    'PG': 675,
    'SO': 252,
    'NO': 47,
    'CC': 61,
    'EE': 372,
    'BN': 673,
    'AU': 61,
    'HM': 0,
    'ML': 223,
    'BD': 880,
    'GE': 995,
    'US': 1,
    'UY': 598,
    'SM': 378,
    'NG': 234,
    'BE': 32,
    'KY': 1,
    'AR': 54,
    'CR': 506,
    'VA': 39,
    'YE': 967,
    'TR': 90,
    'CV': 238,
    'DM': 1,
    'ZM': 260,
    'BR': 55,
    'MG': 261,
    'BL': 590,
    'FJ': 679,
    'SH': 290,
    'KN': 1,
    'ZA': 27,
    'CF': 236,
    'ZW': 263,
    'PL': 48,
    'SV': 503,
    'QA': 974,
    'MN': 976,
    'SE': 46,
    'JE': 44,
    'PS': 970,
    'MZ': 258,
    'TK': 690,
    'PM': 508,
    'CW': 599,
    'HK': 852,
    'LB': 961,
    'SY': 963,
    'LC': 1,
    'IE': 353,
    'RW': 250,
    'NL': 31,
    'MA': 212,
    'GM': 220,
    'IR': 98,
    'AT': 43,
    'SZ': 268,
    'GT': 502,
    'MT': 356,
    'BQ': 599,
    'MX': 52,
    'NC': 687,
    'CK': 682,
    'SI': 386,
    'VE': 58,
    'IM': 44,
    'AM': 374,
    'SD': 249,
    'LY': 218,
    'LI': 423,
    'TN': 216,
    'UG': 256,
    'RU': 7,
    'DJ': 253,
    'IL': 972,
    'TM': 993,
    'BF': 226,
    'GF': 594,
    'TO': 676,
    'GI': 350,
    'MH': 692,
    'UZ': 998,
    'PF': 689,
    'KZ': 7,
    'GA': 241,
    'PE': 51,
    'TV': 688,
    'BT': 975,
    'MQ': 596,
    'MF': 590,
    'AF': 93,
    'IN': 91,
    'AX': 358,
    'BH': 973,
    'JM': 1,
    'MY': 60,
    'BO': 591,
    'AI': 1,
    'SR': 597,
    'ET': 251,
    'ES': 34,
    'TF': 0,
    'GU': 1,
    'BJ': 229,
    'SS': 211,
    'KE': 254,
    'BZ': 501,
    'IO': 246,
    'MU': 230,
    'CL': 56,
    'MD': 373,
    'LU': 352,
    'TJ': 992,
    'EC': 593,
    'VG': 1,
    'NZ': 64,
    'VU': 678,
    'FO': 298,
    'LR': 231,
    'AL': 355,
    'GB': 44,
    'AS': 1,
    'IT': 39,
    'TC': 1,
    'TW': 886,
    'BI': 257,
    'HU': 36,
    'TL': 670,
    'GG': 44,
    'PN': 0,
    'SG': 65,
    'LS': 266,
    'KH': 855,
    'FR': 33,
    'BV': 0,
    'CX': 61,
    'AE': 971,
    'LT': 370,
    'PT': 351,
    'KR': 82,
    'BB': 1,
    'TG': 228,
    'AQ': 0,
    'EH': 212,
    'AG': 1,
    'VN': 84,
    'CI': 225,
    'BS': 1,
    'GL': 299,
    'MW': 265,
    'NU': 683,
    'NF': 672,
    'LK': 94,
    'MS': 1,
    'GP': 590,
    'NP': 977,
    'PW': 680,
    'PK': 92,
    'WF': 681,
    'BA': 387,
    'KM': 269,
    'JO': 962,
    'CU': 53,
    'GR': 30,
    'YT': 262,
    'RS': 381,
    'NA': 264,
    'ST': 239,
    'SC': 248,
    'CN': 86,
    'CD': 243,
    'GS': 0,
    'KW': 965,
    'MM': 95,
    'AO': 244,
    'MV': 960,
    'UA': 380,
    'TT': 1,
    'FK': 500,
    'WS': 685,
    'CZ': 420,
    'PH': 63,
    'VI': 1,
    'TZ': 255,
    'MR': 222,
    'MC': 377,
    'SN': 221,
    'HT': 509,
    'VC': 1,
    'NI': 505,
    'GD': 1,
    'GY': 592,
    'TH': 66
  };
  void donesignup() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (BuildContext context) => AuthenticationWrapper(
                analytics: widget.analytics,
              ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: "AuthenticationWrapper")),
    );
  }

  Future<void> sendfriendrequest(AppUser user, int index) async {
    try {
      await db.sendfriendrequest(
          FirebaseAuth.instance.currentUser!.uid, user.uid);
      logic.displayErrorSnackBar("Sent friend request", context);
      setState(() {
        friends.removeAt(index);
      });
    } catch (e) {
      logic.displayErrorSnackBar("Could not send friend request", context);
    }
  }

  void setup() async {
    if (await fc.FlutterContacts.requestPermission()) {
      try {
        setState(() {
          showcontacts = true;
          loading = true;
        });
        List<Contact> contacts = await ContactsService.getContacts();
        var response = await http.get(Uri.parse("http://ip-api.com/json"));
        final jsonResponse = jsonDecode(response.body);
        String countrycode = jsonResponse["countryCode"];
        List<String> phonenumbers = [];
        for (int i = 0; i < contacts.length; i++) {
          for (int j = 0; j < contacts[i].phones!.toList().length; j++) {
            if (contacts[i].phones!.toList()[j].value!.startsWith("00")) {
              phonenumbers.add(contacts[i]
                  .phones!
                  .toList()[j]
                  .value!
                  .replaceFirst("00", "+")
                  .replaceAll(" ", ""));
            } else if (contacts[i].phones!.toList()[j].value!.startsWith("+")) {
              phonenumbers.add(
                  contacts[i].phones!.toList()[j].value!.replaceAll(" ", ""));
            } else {
              phonenumbers.add("+" +
                  countrycode +
                  contacts[i].phones!.toList()[j].value!.replaceAll(" ", ""));
            }
          }
        }

        List<AppUser> suggestions = await db.getUsersfromContacts(phonenumbers);
        List<AppUser> finalsuggestions = [];
        for (int i = 0; i < suggestions.length; i++) {
          if (!widget.curruser.friends.contains(suggestions[i].uid) &&
              !widget.curruser.requestedby.contains(suggestions[i].uid) &&
              widget.curruser.uid != suggestions[i].uid) {
            finalsuggestions.add(suggestions[i]);
          }
        }
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() {
          friends = finalsuggestions;
          loading = false;
        });
      } catch (e) {
        logic.displayErrorSnackBar(
            "Could not load friend suggestions", context);
        setState(() {
          loading = false;
          showcontacts = false;
        });
      }
    } else {
      setState(() {
        loading = false;
        showcontacts = false;
      });
    }
  }

  navigate(AppUser user) {}

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Add your friends.",
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 25),
            textScaler: const TextScaler.linear(1.0),
          ),
          leading: widget.loggedin
              ? GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : Container(),
          centerTitle: true,
          backgroundColor: Colors.white,
          shadowColor: Colors.white,
          elevation: 0.0,
          automaticallyImplyLeading: false,
        ),
        body: showcontacts
            ? loading
                ? Column(children: [
                    SizedBox(
                      height: screenheight * 0.2,
                    ),
                    Center(
                      child: SpinKitThreeInOut(
                        color: Theme.of(context).primaryColor,
                        size: screenwidth * 0.1, //14?
                      ),
                    ),
                  ])
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        UnAuthUserListView(
                          userres: friends,
                          onTap: navigate,
                          screenwidth: screenwidth,
                          showaddfriend: true,
                          physics: const NeverScrollableScrollPhysics(),
                          sendRequest: sendfriendrequest,
                        ),
                        !widget.loggedin
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: GestureDetector(
                                  onTap: () {
                                    donesignup();
                                  },
                                  child: PrimaryButton(
                                      screenwidth: screenwidth,
                                      buttonpressed: false,
                                      text: "Continue",
                                      buttonwidth: screenwidth * 0.6,
                                      bold: true),
                                ),
                              )
                            : Container(),
                        SizedBox(
                          height: screenheight * 0.05,
                        )
                      ],
                    ),
                  )
            : Column(children: [
                SizedBox(
                  height: screenheight * 0.2,
                ),
                const Center(
                  child: Text(
                    "Need Contact Permission\nto suggest friends.",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
                !widget.loggedin
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: GestureDetector(
                          onTap: () {
                            donesignup();
                          },
                          child: PrimaryButton(
                              screenwidth: screenwidth,
                              buttonpressed: false,
                              text: "Skip",
                              buttonwidth: screenwidth * 0.6,
                              bold: true),
                        ),
                      )
                    : Container(),
              ]));
  }
}
