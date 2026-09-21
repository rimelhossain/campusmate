import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/pages/login.dart';
import 'package:campusmate/ui/pages/otp.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:campusmate/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    final emailField = TextEditingController();
    final nameField = TextEditingController();
    final idField = TextEditingController();
    final pass1Field = TextEditingController();
    final pass2Field = TextEditingController();

    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) =>
          current is SignUpErrorState ||
          current is UnconfirmedEmailState ||
          current is AccountExistsState,
      listener: (context, state) {
        if (state is SignUpErrorState) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
          return;
        } else if (state is UnconfirmedEmailState) {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OTP(state.email)),
          );
          return;
        } else if (state is AccountExistsState) {
          FocusManager.instance.primaryFocus?.unfocus();
          showAdaptiveDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              constraints: BoxConstraints.loose(Size(400, 500)),
              content: const Qstext(
                "Account with this email already exists!!!",
              ),
              icon: Icon(Icons.warning),
              title: const Qstext("Account Exists"),
              actions: [
                TextButton(
                  child: const Qstext("Click Here to Login"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (_) => Login()),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Qstext(
            "CampusMate - Sign Up",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16),
            child: Flex(
              direction: Axis.vertical,
              spacing: 16,
              children: [
                Hero(
                  tag: "img",
                  curve: Easing.legacyAccelerate,
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: secondaryColor,
                    ),
                    child: Image.asset("assets/images/signup.png"),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameField,
                  decoration: InputDecoration(
                    helperText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Qstext("Full Name"),
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) =>
                      isValidName(value != null ? value.trim() : ""),
                ),
                TextFormField(
                  controller: emailField,
                  decoration: InputDecoration(
                    helperText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Qstext("UIU Provided Student email"),
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) =>
                      isValidEmail(value != null ? value.trim() : ""),
                ),
                TextFormField(
                  controller: idField,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    helperText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Qstext("Student ID"),
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) =>
                      isValidID(value != null ? value.trim() : ""),
                ),
                TextFormField(
                  controller: pass1Field,
                  obscureText: true,
                  decoration: InputDecoration(
                    helperText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Qstext("Password"),
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) =>
                      isValidPass(value != null ? value.trim() : ""),
                ),
                TextFormField(
                  controller: pass2Field,
                  obscureText: true,
                  decoration: InputDecoration(
                    helperText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Qstext("Confirm password"),
                  ),
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: (value) => matchPasswords(
                    pass1Field.value.text,
                    value != null ? value.trim() : "",
                  ),
                  onFieldSubmitted: (value) => context.read<CmBloc>().add(
                    SignUpPressedEvent(
                      nameField.value.text,
                      emailField.value.text,
                      idField.value.text,
                      pass1Field.value.text,
                      value,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<CmBloc, CmState>(
                  buildWhen: (previous, current) =>
                      current is SigningUpState || current is SignUpErrorState,
                  builder: (context, state) {
                    if (state is SigningUpState) {
                      return FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(fixedSize: Size(300, 40)),
                        child: CircularProgressIndicator(
                          color: const Color(0xFFC0FBFF),
                          strokeWidth: 2,
                          constraints: BoxConstraints.tight(Size(20, 20)),
                        ),
                      );
                    }
                    return FilledButton(
                      onPressed: () => context.read<CmBloc>().add(
                        SignUpPressedEvent(
                          nameField.value.text,
                          emailField.value.text,
                          idField.value.text,
                          pass1Field.value.text,
                          pass2Field.value.text,
                        ),
                      ),
                      style: FilledButton.styleFrom(fixedSize: Size(300, 40)),
                      child: const Qstext(
                        "Create Account",
                        style: TextStyle(color: Color(0xFFF1FFFC)),
                      ),
                    );
                  },
                ),
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
                    const Qstext("Already Have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Login()),
                      ),
                      child: const Qstext(
                        "Login",
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
  }
}
