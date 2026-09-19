import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LostAndFoundItem {
  final String id;
  final DateTime createdAt;
  final String title;
  final String description;
  final String authorId;
  final String type;
  final String location;
  final TimeOfDay time;
  final ImageProvider imageProvider;
  bool isResolved;

  LostAndFoundItem({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.isResolved,
    required this.authorId,
    required this.type,
    required this.location,
    required this.time,
    required this.imageProvider,
  });

  Future<void> resolve() async {
    final sbclient = Supabase.instance.client;
    await sbclient.from("posts").update({"isResolved": true}).eq("id", id);
    isResolved = true;
  }
}
