import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';

String? isValidEmail(String email) {
  if (email.isEmpty) {
    return "Email is a required value!";
  }

  if (!RegExp(
    r"^[a-z]{2,}[0-9]{6,7}@(bscse|bsce|bseee|bsds|bba)\.uiu\.ac\.bd$",
  ).hasMatch(email)) {
    return "Please use the UIU provided student email";
  }

  return null;
}

String? isValidID(String id) {
  if (id.isEmpty) {
    return "Student ID is a required Value!";
  }

  if (!RegExp(r"^[0-5]{3}[1-9]{3}[0-9]{3,4}$").hasMatch(id)) {
    return "Invalid Student ID";
  }

  return null;
}

String? isValidPass(String pass) {
  if (pass.isEmpty) {
    return "Password is a required value!";
  }

  if (pass.length < 8) {
    return "Password must be at least 8 characters";
  }

  return null;
}

String? matchPasswords(String pass1, String pass2) {
  if (pass1.isEmpty || pass2.isEmpty) {
    return "Password is a required value";
  }

  if (pass1.compareTo(pass2) != 0) {
    return "Passwords do not match";
  }

  return null;
}

String? isValidName(String name) {
  if (name.isEmpty) {
    return "Name is a required value";
  }

  if (name.length < 2) {
    return "Invalid Name";
  }

  return null;
}

String? finalCheck(
  String name,
  String email,
  String id,
  String pass1,
  String pass2,
) {
  if (isValidEmail(email) != null ||
      isValidID(id) != null ||
      isValidPass(pass1) != null ||
      matchPasswords(pass1, pass2) != null) {
    return "Please fillout the fields correctly";
  }

  // Name and email match
  final emailPrefix = email.split(RegExp(r"[0-9]{6,7}@")).first;

  final emailPrefixFromName = (name.substring(0, 1) + name.split(" ").last)
      .toLowerCase();

  if (emailPrefixFromName.compareTo(emailPrefix) != 0) {
    return "Please use the name from your Student ID card";
  }

  // id and email match
  final idFromEmail = RegExp(r"[0-9]{6,7}").stringMatch(email);

  debugPrint(idFromEmail);

  if (idFromEmail == null) {
    return "Invalid Email 2";
  }

  final idWithoutProgramCode = id.substring(3);

  if (idWithoutProgramCode.compareTo(idFromEmail) != 0) {
    return "Id and Email did not match";
  }

  // Id and Department match
  final programFromEmail = RegExp(
    r"(bscse|bsce|bseee|bsds|bba)",
  ).stringMatch(email);

  if (programFromEmail == null) {
    return "Invalid Email 3";
  }

  debugPrint(programFromEmail);
  debugPrint(id.substring(0, 3));
  final programFromId = program[id.substring(0, 3)];

  debugPrint(programFromId);

  if (programFromId == null) {
    return "Invalid Student ID";
  }

  if (programFromId.compareTo(programFromEmail) != 0) {
    return "Mismatching ID and Department";
  }

  return null;
}
