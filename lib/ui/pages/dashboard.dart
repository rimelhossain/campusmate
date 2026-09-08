import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/academics_feature_card.dart';
import 'package:campusmate/ui/components/campus_life_feature_card.dart';
import 'package:campusmate/ui/components/hero_card.dart';
import 'package:campusmate/ui/pages/landing.dart';
import 'package:campusmate/ui/pages/lost_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) => current is LoggedOutState,
      listener: (context, state) {
        if (state is LoggedOutState) {
          Navigator.popUntil(context, (x) => x.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Landing()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFE9ECEA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: double.infinity),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Qstext(
                      "Assalamualaikum,",
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                      child: IconButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          fixedSize: WidgetStatePropertyAll(Size(44, 44)),
                        ),
                        constraints: BoxConstraints.tight(Size(44, 44)),

                        tooltip: "Notifications",
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                Qstext(
                  student.name,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Qstext(
                  "${student.dept.toUpperCase()} | ${student.trimester}-${student.year}",
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 24),
                HeroCard(),
                SizedBox(height: 32),
                Qstext(
                  "Campus Life",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      spacing: 16,
                      children: [
                        CampusLifeFeatureCard(
                          "Marketplace",
                          Icons.shopping_bag_outlined,
                        ),
                        CampusLifeFeatureCard(
                          "Lost And Found",
                          Icons.search,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: ((context) => LostFeed()),
                            ),
                          ),
                        ),
                        CampusLifeFeatureCard(
                          "Fresher's Corner",
                          Icons.home_outlined
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Qstext(
                  "Academics",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      spacing: 16,
                      children: [
                        AcademicsFeatureCard("Study Help", Icons.book_outlined),
                        AcademicsFeatureCard(
                          "AI Quiz",
                          Icons.thunderstorm_outlined,
                        ),
                        AcademicsFeatureCard(
                          "CGPA Calculator",
                          Icons.calculate_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
