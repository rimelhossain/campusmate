import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/pages/dashboard.dart';
import 'package:campusmate/ui/pages/otp.dart';
import 'package:campusmate/ui/pages/pass_reset_otp.dart';
import 'package:campusmate/ui/pages/signup.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailField = TextEditingController();
  final passField = TextEditingController();
  bool showPass = false;
  Future<SharedPreferences>? pref;

  @override
  void initState() {
    pref = SharedPreferences.getInstance();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: pref,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && !snapshot.hasError) {
          emailField.text = snapshot.data!.getString("userEmail")??"";
        }
        return BlocListener<CmBloc, CmState>(
          listenWhen: (previous, current) =>
              current is LoginErrorState ||
              current is LoginSuccessState ||
              current is PassResetReqSentState ||
              current is PassResetErrorState ||
              current is UnconfirmedEmailState,
          listener: (context, state) {
            if (state is LoginErrorState) {
              FocusManager.instance.primaryFocus?.unfocus();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Qstext(state.msg)));
            } else if (state is UnconfirmedEmailState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OTP(emailField.value.text.trim()),
                ),
              );
            } else if (state is LoginSuccessState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Dashboard()),
              );
            } else if (state is PassResetReqSentState) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PassResetOtp(state.email)),
              );
            } else if (state is PassResetErrorState) {
              FocusManager.instance.primaryFocus?.unfocus();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Qstext(state.msg)));
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Qstext(
                "CampusMate - Login",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.vertical,
                child: Flex(
                  direction: Axis.vertical,
                  spacing: 16,
                  children: [
                    Hero(
                      tag: "img",
                      child: Container(
                        // Image
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset("assets/images/login.png"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailField,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        label: const Qstext("UIU Provided Student email"),
                      ),
                    ),
                    BlocBuilder<CmBloc, CmState>(
                      buildWhen: (previous, current) =>
                          current is PassToggleState,
                      builder: (context, state) {
                        if (state is PassToggleState) {
                          showPass = !showPass;
                        }
                        return TextFormField(
                          controller: passField,
                          obscureText: !showPass,
                          onFieldSubmitted: (value) =>
                              context.read<CmBloc>().add(
                                LoginRequestedEvent(
                                  emailField.value.text.trim(),
                                  value.trim(),
                                ),
                              ),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  context.read<CmBloc>().add(PassToggleEvent()),
                              icon: Icon(
                                showPass
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            label: const Qstext("Password"),
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BlocBuilder<CmBloc, CmState>(
                          buildWhen: (previous, current) =>
                              current is PasswordResetSendingState ||
                              current is PassResetErrorState,
                          builder: (context, state) {
                            if (state is PasswordResetSendingState) {
                              return Container(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  right: 32,
                                ),
                                width: 96,
                                child: LinearProgressIndicator(),
                              );
                            }
                            return TextButton(
                              onPressed: () => context.read<CmBloc>().add(
                                PasswordResetEvent(
                                  emailField.value.text.trim(),
                                ),
                              ),
                              child: const Qstext("Forgot Password?"),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<CmBloc, CmState>(
                      buildWhen: (previous, current) =>
                          current is LoginErrorState ||
                          current is LoggingInState,
                      builder: (context, state) {
                        if (state is LoggingInState) {
                          return FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              fixedSize: Size(300, 40),
                            ),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(20, 20)),
                              strokeWidth: 2,
                            ),
                          );
                        }
                        return FilledButton(
                          onPressed: () => context.read<CmBloc>().add(
                            LoginRequestedEvent(
                              emailField.value.text.trim(),
                              passField.value.text.trim(),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            fixedSize: Size(300, 40),
                          ),
                          child: const Qstext(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFFF1FFFC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      direction: Axis.horizontal,
                      runAlignment: WrapAlignment.center,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      textDirection: TextDirection.ltr,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        const Qstext("Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Signup()),
                          ),
                          child: const Qstext(
                            "Sign Up",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
