import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/components/topbar.dart';
import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Topbar(title: "About"),
      body: Center(
        child: const Qstext("About Page", style: TextStyle(fontSize: 28)),
      ),
    );
  }
}
