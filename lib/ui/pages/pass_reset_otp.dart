import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/components/resend_timer.dart';
import 'package:campusmate/ui/pages/choose_pass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassResetOtp extends StatefulWidget {
  final String email;

  const PassResetOtp(this.email, {super.key});

  @override
  State<PassResetOtp> createState() => _PassResetOtpState();
}

class _PassResetOtpState extends State<PassResetOtp> {
  final tokenField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) =>
          current is OtpErrorState || current is OtpVerificationSuccessState,
      listener: (context, state) {
        if (state is OtpErrorState) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
        } else if (state is OtpVerificationSuccessState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChoosePass()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Qstext("Password Reset")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Flex(
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              Text.rich(
                TextSpan(
                  text: "An OTP was sent to ",
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: "Quicksand",
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontFamily: "Quicksand"),
              ),
              const Qstext("Please enter the code below to continue"),
              const SizedBox(height: 32, width: double.infinity),
              TextFormField(
                controller: tokenField,
                maxLength: 6,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  constraints: BoxConstraints.tight(Size(256, 64)),
                  hint: const Text(
                    "* * * * * *",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "Quicksand", fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<CmBloc>().add(
                  OtpConfimationEvent(
                    tokenField.value.text.trim(),
                    widget.email,
                    OtpType.recovery,
                  ),
                ),
                style: FilledButton.styleFrom(fixedSize: Size(128, 32)),
                child: const Qstext("Proceed"),
              ),
              const SizedBox(height: 48),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  const Qstext("Didn't receive email? "),
                  const Qstext("You can resend OTP after "),
                  ResendTimer(),
                ],
              ),
              BlocBuilder<CmBloc, CmState>(
                buildWhen: (previous, current) =>
                    current is OtpTimerEndedState ||
                    current is OtpResendingState ||
                    current is OtpResentState,
                builder: (context, state) {
                  if (state is OtpTimerEndedState) {
                    return ElevatedButton(
                      onPressed: () => context.read<CmBloc>().add(
                        OtpResendRequestedEvent(widget.email, OtpType.recovery),
                      ),
                      child: const Qstext("Resend"),
                    );
                  } else if (state is OtpResendingState) {
                    return ElevatedButton(
                      onPressed: () {},
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        constraints: BoxConstraints.tight(Size(20, 20)),
                      ),
                    );
                  }
                  return ElevatedButton(
                    onPressed: null,
                    child: const Qstext("Resend"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
