import 'package:clout/components/primarybutton.dart';
import 'package:clout/services/logic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PswResetScreen extends StatefulWidget {
  PswResetScreen({Key? key}) : super(key: key);

  @override
  State<PswResetScreen> createState() => _PswResetScreenState();
}

class _PswResetScreenState extends State<PswResetScreen> {
  TextEditingController email = TextEditingController();
  bool resetbuttonpressed = false;
  applogic logic = applogic();
  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Please enter the email address associated with your account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: screenheight * 0.02,
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenwidth * 0.2),
                  child: TextField(
                    decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                        hintText: 'e.g. example@outwithclout.com',
                        hintStyle: const TextStyle(
                            color: Color.fromARGB(39, 0, 0, 0))),
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    enableSuggestions: false,
                    autocorrect: false,
                  ),
                ),
              ),
              SizedBox(
                height: screenheight * 0.03,
              ),
              InkWell(
                  onTap: resetbuttonpressed
                      ? null
                      : () async {
                          setState(() {
                            resetbuttonpressed = true;
                          });
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: email.text.trim());
                            logic.displayErrorSnackBar(
                                "Password Reset Email Sent", context);
                          } catch (e) {
                            logic.displayErrorSnackBar(
                                "Could not send email, check internet connection or ensure email address is valid",
                                context);
                          } finally {
                            setState(() {
                              resetbuttonpressed = false;
                            });
                          }
                        },
                  child: PrimaryButton(
                    screenwidth: screenwidth,
                    buttonpressed: resetbuttonpressed,
                    text: "Send Password Reset Email",
                    buttonwidth: screenwidth * 0.8,
                    bold: false,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
