import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Qstext("Profile")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  spacing: 4,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        height: 128,
                        width: 128,
                        child: student.image,
                      ),
                    ),
                    SizedBox(width: double.infinity, height: 16),
                    Text(
                      student.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        letterSpacing: 3,
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Qstext(
                      student.email,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        SizedBox(width: 16),
                        Qstext(
                          "Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        border: BoxBorder.all(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            minTileHeight: 48,
                            leading: Icon(Icons.edit),
                            title: Qstext(
                              "Edit Profile",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            contentPadding: EdgeInsets.all(16),
                            onTap: () {},
                          ),
                          Divider(),
                          ListTile(
                            minTileHeight: 48,
                            leading: Icon(Icons.shopping_bag),
                            title: Qstext(
                              "My Marketplace Posts",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            contentPadding: EdgeInsets.all(16),
                            onTap: () {},
                          ),
                          Divider(),
                          ListTile(
                            minTileHeight: 48,
                            leading: Icon(Icons.notifications),
                            title: Qstext(
                              "Notifications",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            contentPadding: EdgeInsets.all(16),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(fixedSize: Size(256, 48)),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Qstext("Logout?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<CmBloc>().add(LogoutRequestedEvent());
                        },
                        child: Qstext(
                          "Yes, Logout!",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Qstext(
                          "No, Stay Logged in!",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                child: Qstext(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
