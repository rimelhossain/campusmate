import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';

class LostAndFoundCard extends StatelessWidget {
  final LostAndFoundItem item;
  const LostAndFoundCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card.filled(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(16),
        ),
        elevation: 2,
        color: Color(0xFFF8DCBD),
        child: Container(
          padding: EdgeInsetsGeometry.all(24),
          child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 25,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Color(0xFFF5AC7C),
                        borderRadius: BorderRadiusGeometry.circular(8),
                      ),
                      child: Center(
                        child: Qstext(
                          "${item.type.substring(0, 1).toUpperCase()}${item.type.substring(1)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Qstext(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      item.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: "Quicksand",
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.red),
                        Qstext(item.location),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 24,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(16),
                      child: item.image,
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(0xFF00994C),
                      ),
                      child: Qstext("View details"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
