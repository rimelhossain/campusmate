import 'package:campusmate/utils/constants.dart';

class Student {
  late String __name;
  late String __id;
  late String __email;
  late String __dept;
  late String __trimester;
  late int __year;

  Student(Map<String, dynamic> info) {
    __id = info["sid"];
    __name = info["name"];
    __email = info["email"];

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
}
