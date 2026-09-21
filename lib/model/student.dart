import 'package:campusmate/utils/constants.dart';
import 'package:campusmate/utils/helpers.dart';
import 'package:flutter/material.dart';

class Student {
  late String __name;
  late String __id;
  late String __email;
  late String __dept;
  late String __trimester;
  late int __year;
  late String __photoUrl;

  Student(Map<String, dynamic> info) {
    __id = info["sid"];
    __name = info["name"];
    __email = info["email"];
    __photoUrl = info["photourl"] ?? "";
    __dept = program[__id.substring(0, 3)]!;
    __trimester = trimesters[int.parse(__id.substring(5, 6)) - 1];
    __year = int.parse(__id.substring(3, 5));
  }

  String get name => capitalizePerWords(__name);
  String get id => __id;
  String get email => __email;
  String get dept => __dept;
  String get trimester => __trimester;
  int get year => __year;
  ImageProvider get imageProvider => __photoUrl.isEmpty
      ? AssetImage("assets/images/default-avatar.png")
      : NetworkImage(__photoUrl);
  Widget get image => Image(image: imageProvider);
}
