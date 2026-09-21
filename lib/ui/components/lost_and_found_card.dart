import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/pages/lost_and_found_details.dart';
import 'package:campusmate/utils/helpers.dart';
import 'package:flutter/material.dart';

class LostAndFoundCard extends StatelessWidget {
  final LostAndFoundItem item;
  const LostAndFoundCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = item.type == "lost" ? Colors.white : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card.filled(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(16),
        ),
        elevation: 2,
        color: item.type == "found" ? Color(0xFFFFD6AC) : Color(0xFF6B8AAE),
        child: Container(
          padding: EdgeInsetsGeometry.all(24),
          child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.type == "found"
                            ? Color(0xFF3EC07F)
                            : Color(0xFFF5AC7C),
                        borderRadius: BorderRadiusGeometry.circular(8),
                      ),
                      child: Center(
                        child: Qstext(
                          "${capitalizePerWords(item.type)}${item.isResolved ? ' (Resolved)' : ''}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: item.type == "found" ? Colors.white : null,
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
                        color: textColor,
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
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: item.type == "found"
                              ? Colors.red
                              : Color(0xFF00FCAC),
                        ),
                        Qstext(
                          item.location,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LostAndFoundDetails(item),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: item.type == "found"
                            ? Color(0xFF3EC07F)
                            : Color(0xFFD53939),
                      ),
                      child: Qstext("View details"),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LostAndFoundDetails(item),
                      ),
                    ),
                    child: Hero(
                      tag: item.id,
                      child: Image(
                        image: item.imageProvider,
                        errorBuilder: (context, error, stackTrace) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Qstext(
                            "Image Could not be loaded or no Image provided",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return LinearProgressIndicator(
                            value: loadingProgress.expectedTotalBytes == null
                                ? null
                                : loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
