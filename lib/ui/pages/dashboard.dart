import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/topbar.dart';
import 'package:campusmate/ui/pages/landing.dart';
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
        appBar: Topbar(title: "Dashboard"),
        body: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: double.infinity),
              const Qstext("Login Successfull", style: TextStyle(fontSize: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
