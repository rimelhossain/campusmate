import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(24),
      ),
      elevation: 4,
      color: const Color(0xFF0C3621),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Flex(
          spacing: 24,
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                verticalDirection: VerticalDirection.down,
                spacing: 16,
                children: [
                  Qstext(
                    "Trimester Fee",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFFE09C2E),
                      borderRadius: BorderRadiusGeometry.circular(12),
                    ),
                    child: Center(
                      child: Qstext(
                        "3 Days Left",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Payment Due Soon!!!",
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontFamily: "Quicksand",
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 16,
                children: [
                  Qstext(
                    "Deadline: 12 September",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    iconAlignment: IconAlignment.end,
                    icon: Icon(Icons.arrow_forward, color: Colors.black),
                    label: Qstext(
                      "Calculate",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        const EdgeInsetsDirectional.symmetric(
                          horizontal: 26,
                          vertical: 20,
                        ),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(12),
                        ),
                      ),
                      backgroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
