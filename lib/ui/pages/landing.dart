import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/pages/login.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';

class Landing extends StatelessWidget {
  const Landing({super.key});

  @override
  Widget build(BuildContext context) {
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
                    style: FilledButton.styleFrom(
                      fixedSize:Size(256, 64),
                    ),
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
  }
}
