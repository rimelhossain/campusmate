import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/app_bloc.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: FilledButton(
    onPressed: context.select((AppBloc bloc) => bloc.state.isBusy) ? null : onPressed,
    child: Padding(padding: const EdgeInsets.all(14), child: context.select((AppBloc bloc) => bloc.state.isBusy)
      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : Text(label)),
  ));
}
