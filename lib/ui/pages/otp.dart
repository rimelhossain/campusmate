import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/components/resend_timer.dart';
import 'package:campusmate/ui/pages/dashboard.dart';
import 'package:campusmate/ui/pages/landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OTP extends StatelessWidget {
  final String email;
  const OTP(this.email, {super.key});

  @override
  Widget build(BuildContext context) {
    final otpField = TextEditingController();

    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) =>
          current is OtpErrorState || current is SignUpSuccessState,
      listener: (context, state) {
        if (state is OtpErrorState) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
        } else if (state is SignUpSuccessState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Dashboard()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Qstext("Email Verification"),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Flex(
            direction: Axis.vertical,
            spacing: 8,
            children: [
              Spacer(),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  text: "An OTP has been sent to ",
                  children: [
                    TextSpan(
                      text: email,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 18, fontFamily: "Quicksand"),
              ),
              const Qstext(
                "Please enter the OTP below.",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16, width: double.infinity),
              SizedBox(
                width: 128,
                child: TextFormField(
                  controller: otpField,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: TextStyle(fontFamily: "Quicksand", fontSize: 28),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hint: Text(
                      "* * * * * *",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              BlocBuilder<CmBloc, CmState>(
                buildWhen: (previous, current) =>
                    current is ConfirmingOtpState || current is OtpErrorState,
                builder: (context, state) {
                  if (state is ConfirmingOtpState) {
                    return FilledButton(
                      onPressed: () {},
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        constraints: BoxConstraints.tight(Size(20, 20)),
                        strokeWidth: 2,
                      ),
                    );
                  }
                  return FilledButton(
                    onPressed: () => context.read<CmBloc>().add(
                      OtpConfimationEvent(
                        otpField.value.text.trim(),
                        email,
                        OtpType.email,
                      ),
                    ),
                    child: const Qstext(
                      "Proceed Confirmation",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.horizontal,
                runAlignment: WrapAlignment.center,
                runSpacing: 16,
                verticalDirection: VerticalDirection.down,
                children: [
                  const Qstext("Still not received the OTP? "),
                  const Qstext("You can request a resend after "),
                  ResendTimer(),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<CmBloc, CmState>(
                buildWhen: (previous, current) =>
                    current is OtpTimerEndedState ||
                    current is OtpResentState ||
                    current is OtpResendingState ||
                    current is OtpErrorState,
                builder: (context, state) {
                  if (state is OtpTimerEndedState) {
                    return ElevatedButton(
                      onPressed: () => context.read<CmBloc>().add(
                        OtpResendRequestedEvent(email, OtpType.email),
                      ),
                      child: const Qstext("Resend"),
                    );
                  } else if (state is OtpResendingState) {
                    return ElevatedButton(
                      onPressed: () {},
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        constraints: BoxConstraints.tight(Size(20, 20)),
                        strokeWidth: 2,
                      ),
                    );
                  }
                  return ElevatedButton(
                    onPressed: null,
                    child: const Qstext("Resend"),
                  );
                },
              ),

              Spacer(),
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => CancelConfirmationDialog(),
                ),
                child: const Qstext(
                  "Cancel Account Creation",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class CancelConfirmationDialog extends StatelessWidget {
  const CancelConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Qstext("Cancel Account Creation?"),
      content: const Qstext(
        "It is required to confirm this email within 12 AM tonight. Otherwise, this account will be completely removed!!!",
        style: TextStyle(color: Colors.red),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Landing()),
            );
          },
          child: const Qstext(
            "Yes",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Qstext(
            "No",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
      ],
    );
  }
}
