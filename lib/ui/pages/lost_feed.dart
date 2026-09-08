import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/pages/create_post.dart';
import 'package:flutter/material.dart';

class LostFeed extends StatelessWidget {
  const LostFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: ((context) => CreatePost())),
        ),
        label: Qstext("Add New"),
        icon: Icon(Icons.add),
      ),
      appBar: AppBar(title: Qstext("Lost and Found")),
      body: SafeArea(
        child: Column(
          children: [Row(mainAxisAlignment: MainAxisAlignment.end)],
        ),
      ),
    );
  }
}
