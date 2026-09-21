import 'package:flutter/material.dart';

class LostAndFoundItem {
  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final String authorId;
  final String username;
  final String userSid;
  final String userPhotoUrl;
  final String type;
  final String location;
  final TimeOfDay time;
  final ImageProvider? imageProvider;
  bool isResolved;

  LostAndFoundItem({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.isResolved,
    required this.authorId,
    required this.username,
    required this.userSid,
    required this.userPhotoUrl,
    required this.type,
    required this.location,
    required this.time,
    required this.imageProvider,
  });
}
