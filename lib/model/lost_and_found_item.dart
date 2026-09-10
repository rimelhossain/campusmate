import 'package:flutter/material.dart';

class LostAndFoundItem {
  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final bool isResolved;
  final String authorId;
  final String type;
  final String location;
  final TimeOfDay time;
  final Image image;

  const LostAndFoundItem({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.isResolved,
    required this.authorId,
    required this.type,
    required this.location,
    required this.time,
    required this.image
  });
}
