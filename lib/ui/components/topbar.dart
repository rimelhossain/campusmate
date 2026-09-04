import 'package:campusmate/ui/components/Qstext.dart';
import 'package:flutter/material.dart';

class Topbar extends AppBar {
  Topbar({required String title, super.key})
    : super(title: Qstext(title), leading: DrawerButton());
}
