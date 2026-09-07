import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';

class CampusLifeFeatureCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final GestureTapCallback? onTap;
  const CampusLifeFeatureCard(
    this.title,
    this.iconData, {
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      elevation: 1,
      color: Color(0xFFFFFEFE),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: const Color(0xFFC3DDBC)),
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 128,
          child: Flex(
            direction: Axis.vertical,
            spacing: 16,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEFF6DA),
                  border: Border.all(color: const Color(0xFFC3DDBC)),
                ),
                child: Icon(iconData),
              ),
              Qstext(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
