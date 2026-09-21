import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/academics_feature_card.dart';
import 'package:campusmate/ui/components/campus_life_feature_card.dart';
import 'package:campusmate/ui/components/hero_card.dart';
import 'package:campusmate/ui/pages/landing.dart';
import 'package:campusmate/ui/pages/lost_feed.dart';
import 'package:campusmate/ui/pages/profile_details.dart';
import 'package:campusmate/ui/pages/chat_list.dart';
import 'package:campusmate/ui/pages/study_help_feed.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) => current is LoggedOutState,
      listener: (context, state) {
        if (state is LoggedOutState) {
          Navigator.popUntil(context, (x) => x.isFirst);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Landing()),
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Qstext("Exit???"),
            actions: [
              TextButton(
                onPressed: SystemNavigator.pop,
                child: Qstext(
                  "Yes, Exit now!",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Qstext(
                  "No, Stay here.",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Color(0xFFE9ECEA),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardHome(context),
              const ChatList(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chats',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: double.infinity),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Qstext(
                      "Assalamualaikum,",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Qstext(
                      student.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Qstext(
                      "${student.dept.toUpperCase()} | ${student.trimester}-${student.year}",
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 16,
                  children: [
                    IconButton.filled(
                      onPressed: () {},
                      tooltip: "Notifications",
                      color: textColor,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.notifications),
                    ),
                    Tooltip(
                      message: "Profile Details",
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileDetails(),
                            ),
                          ),
                          child: CircleAvatar(child: student.image),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                      "Lost & Found",
                      Icons.search,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostFeed(),
                        ),
                      ),
                    ),
                    CampusLifeFeatureCard(
                      "Fresher's Corner",
                      Icons.home_outlined,
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
                    AcademicsFeatureCard(
                      "Study Help",
                      Icons.book_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudyHelpFeed(),
                          ),
                        );
                      }
                    ),
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
    );
  }
}
