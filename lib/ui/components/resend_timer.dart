import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResendTimer extends StatefulWidget {
  const ResendTimer({super.key});

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  DateTime end = DateTime.now().add(Duration(seconds: 180));
  bool running = false;
  int difference = 180;
  String time = "180 sec";

  void updateTimer() {
    if (running) {
      difference = end.difference(DateTime.now()).inSeconds.clamp(0, 180);
      setState(() => time = "$difference sec");
      if (difference > 0 && running) {
        Future.delayed(Duration(seconds: 1), updateTimer);
      }
    }
  }

  @override
  void initState() {
    running = true;
    updateTimer();
    super.initState();
  }

  @override
  void dispose() {
    running = false;
    super.dispose();
  }

  void reset() {
    end = DateTime.now().add(Duration(seconds: 180));
    running = true;
    difference = end.difference(DateTime.now()).inSeconds;
    time = "$difference sec";
    updateTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (difference <= 0) {
      context.read<CmBloc>().add(OtpTimerEndedEvent());
      return BlocListener<CmBloc, CmState>(
        listenWhen: (previous, current) => current is OtpResentState,
        listener: (context, state) {
          if (state is OtpResentState) {
            reset();
          }
        },
        child: Qstext(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Qstext(
      time,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
