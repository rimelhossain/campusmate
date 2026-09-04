import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/qstext.dart';
import 'package:campusmate/ui/pages/login.dart';
import 'package:campusmate/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChoosePass extends StatefulWidget {
  const ChoosePass({super.key});

  @override
  State<ChoosePass> createState() => _ChoosePassState();
}

class _ChoosePassState extends State<ChoosePass> {
  final pass1Field = TextEditingController();
  final pass2Field = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CmBloc, CmState>(
      listenWhen: (previous, current) =>
          current is SetPassErrorState || current is SetPassSuccessState,
      listener: (context, state) {
        if (state is SetPassErrorState) {
          FocusManager.instance.primaryFocus?.unfocus();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Qstext(state.msg)));
        } else if (state is SetPassSuccessState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Login()),
          );
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Qstext("Password Reset Successful"),
              content: Qstext(
                "Password has been reset. Now you can login with the new password.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Qstext(
                    "Thanks! :)",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Qstext("Password Reset")),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Flex(
            direction: Axis.vertical,
            spacing: 16,
            children: [
              const SizedBox(height: 48, width: double.infinity),
              const Qstext(
                "Choose your password",
                style: TextStyle(fontSize: 32),
              ),
              TextFormField(
                controller: pass1Field,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: const Qstext("New Password"),
                  helperText: "",
                ),
                autovalidateMode: AutovalidateMode.onUnfocus,
                validator: (value) =>
                    isValidPass(value != null ? value.trim() : ""),
              ),
              TextFormField(
                controller: pass2Field,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  label: const Qstext("Confirm Password"),
                  helperText: "",
                ),
                autovalidateMode: AutovalidateMode.onUnfocus,
                validator: (value) =>
                    isValidPass(value != null ? value.trim() : ""),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.read<CmBloc>().add(
                  SetPassEvent(
                    pass1Field.value.text.trim(),
                    pass2Field.value.text.trim(),
                  ),
                ),
                style: ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(Size(156, 40)),
                ),
                child: const Qstext("Proceed"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
