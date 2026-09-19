import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';

class Student {
  late String __name;
  late String __id;
  late String __email;
  late String __dept;
  late String __trimester;
  late int __year;
  late ImageProvider? __photo;

  Student(Map<String, dynamic> info) {
    __id = info["sid"];
    __name = info["name"];
    __email = info["email"];

    if (info["photoUrl"] != null) {
      __photo = NetworkImage(info["photoUrl"]);
    } else {
      __photo = null;
    }

    __dept = program[__id.substring(0, 3)]!;
    __trimester = trimesters[int.parse(__id.substring(5, 6)) - 1];
    __year = int.parse(__id.substring(3, 5));
  }

  String get name => __name;
  String get id => __id;
  String get email => __email;
  String get dept => __dept;
  String get trimester => __trimester;
  int get year => __year;
  ImageProvider? get imageProvider => __photo;
  Widget get image => __photo == null
      ? Container(
          decoration: BoxDecoration(color: const Color(0xFF1C421D)),
          child: Center(
            child: Qstext(
              __name.substring(0, 1).toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
            ),
          ),
        )
      : Image(image: __photo!);
}
