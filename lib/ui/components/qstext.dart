import 'package:flutter/material.dart';

class Qstext extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const Qstext(this.text, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontFamily: "Quicksand").merge(style));
  }
}
