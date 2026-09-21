import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';

class Response extends StatelessWidget {
  final String username;
  final String sid;
  final String comment;
  const Response(this.username, this.sid, this.comment, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Flex(
          spacing: 24,
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage("assets/images/default-avatar.png"),
              radius: 24,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Qstext(
                    "$username ($sid)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Qstext(comment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
