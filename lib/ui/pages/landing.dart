import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/student.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/pages/dashboard.dart';
import 'package:campusmate/ui/pages/login.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  Future<bool?>? sessionState;

  Future<bool?> trySessionRecovery() async {
    final sbclient = Supabase.instance.client;
    if (sbclient.auth.currentSession != null) {
      if (sbclient.auth.currentSession!.isExpired) {
        await sbclient.auth.refreshSession();
      }
      student = Student(sbclient.auth.currentSession!.user.userMetadata!);
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString("userEmail") != null) {
      return false;
    }
    return null;
  }

  @override
  void initState() {
    sessionState = trySessionRecovery();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sessionState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          if (snapshot.data != null) {
            if (snapshot.data!) {
              return Dashboard();
            } else if (!snapshot.data!) {
              return Login();
            }
          }
        }
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: AlignmentGeometry.center,
                  child: Hero(
                    tag: "img",
                    child: Image.asset("assets/images/landing.png"),
                  ),
                ),
                Flex(
                  direction: Axis.vertical,
                  spacing: 16,
                  children: [
                    const SizedBox(height: 100, width: double.infinity),
                    Qstext(
                      "UIU",
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(
                      width: 200,
                      child: Text(
                        "A Campus That Feels Like Home",
                        textWidthBasis: TextWidthBasis.parent,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Quicksand",
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 42.0),
                      child: FilledButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => Login()),
                        ),
                        style: FilledButton.styleFrom(fixedSize: Size(256, 64)),
                        child: const Qstext(
                          "Get Started",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
