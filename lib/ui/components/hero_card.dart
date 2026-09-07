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
      color: const Color(0xFFF5AC7C),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Flex(
          spacing: 24,
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Qstext(
                  "Trimester Fee",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  height: 40,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  child: Center(
                    child: Qstext(
                      "3 Days Left",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "Payment Due Soon!!!",
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontFamily: "Quicksand",
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Qstext(
                  "Deadline: 12 September",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  iconAlignment: IconAlignment.end,
                  icon: Icon(Icons.arrow_forward, color: Colors.black),
                  label: Qstext(
                    "Calculate",
                    style: TextStyle(color: Colors.black),
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
          ],
        ),
      ),
    );
  }
}
