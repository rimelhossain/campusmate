import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common_ui_components/input_surface.dart';

class TuitionCalculatorPage extends StatefulWidget {
  const TuitionCalculatorPage({super.key});

  @override
  State<TuitionCalculatorPage> createState() => _TuitionCalculatorPageState();
}

class _TuitionCalculatorPageState extends State<TuitionCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _creditsController = TextEditingController();
  final _client = Supabase.instance.client;
  double _waiver = 0;
  bool _calculating = false;

  static const _waiverOptions = <({String label, double value})>[
    (label: 'No waiver', value: 0),
    (label: '25%', value: 0.25),
    (label: '50%', value: 0.5),
    (label: '100%', value: 1),
  ];

  @override
  void dispose() {
    _creditsController.dispose();
    super.dispose();
  }

  String? _validateCredits(String? value) {
    final text = value?.trim() ?? '';
    final credits = int.tryParse(text);
    if (text.isEmpty || credits == null) return 'Enter the credits for this trimester.';
    if (credits <= 0) return 'Credits must be greater than zero.';
    return null;
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _calculating = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw StateError('Please sign in to calculate tuition.');

      final profile = await _client
          .from('campusmate_profiles')
          .select('student_id')
          .eq('user_id', userId)
          .single();
      final studentId = profile['student_id'] as String? ?? '';
      if (studentId.length < 6) {
        throw StateError('Your student ID is incomplete. Update it in your profile.');
      }
      final batchNumber = int.tryParse(studentId.substring(3, 6));
      if (batchNumber == null) {
        throw StateError('Your student ID does not contain a valid batch number.');
      }

      final installments = await _client
          .from('tuition_installments')
          .select('id,label,due_on')
          .order('id');
      final installmentsById = <int, Map<String, dynamic>>{
        for (final row in installments)
          (row['id'] as num).toInt(): Map<String, dynamic>.from(row),
      };
      if ([1, 2, 3].any((id) =>
          installmentsById[id] == null ||
          installmentsById[id]!['due_on'] == null)) {
        throw StateError('Installment deadlines are not available yet.');
      }

      final credits = int.parse(_creditsController.text.trim());
      final creditFee = batchNumber < 252 ? 5525 : 6500;
      final tuitionAmount = credits * creditFee * (1 - _waiver) + 6500;
      final first = (tuitionAmount * 0.4).ceil();
      final second = (tuitionAmount * 0.3).ceil();
      final third = (tuitionAmount - (first + second)).ceil();
      final amounts = [first, second, third];
      final deadlines = [1, 2, 3].map((id) {
        final date = DateTime.parse(installmentsById[id]!['due_on'] as String);
        return MaterialLocalizations.of(context).formatMediumDate(date);
      }).toList();

      if (!mounted) return;
      await _showInstallments(amounts, deadlines);
    } on PostgrestException catch (error) {
      _showError(error.message);
    } on StateError catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not calculate tuition right now. Please try again.');
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInstallments(List<int> amounts, List<String> deadlines) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: const Text('Calculated Installments'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < 3; index++) ...[
                  _InstallmentCard(
                    number: index + 1,
                    amount: amounts[index],
                    deadline: deadlines[index],
                  ),
                  if (index < 2) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tuition Fee Calculator'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
                  children: [
                    Text(
                      'Estimate your trimester tuition',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your current trimester credits and waiver to see the installment amounts.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    InputSurface(
                      child: TextFormField(
                        controller: _creditsController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Taken credits this trimester',
                          hintText: 'For example, 12',
                          prefixIcon: Icon(Icons.credit_score_outlined),
                        ),
                        validator: _validateCredits,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<double>(
                      initialValue: _waiver,
                      decoration: const InputDecoration(
                        labelText: 'Waiver percentage',
                        prefixIcon: Icon(Icons.discount_outlined),
                      ),
                      items: [
                        for (final option in _waiverOptions)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: _calculating
                          ? null
                          : (value) {
                              if (value != null) setState(() => _waiver = value);
                            },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _calculating ? null : _calculate,
                        icon: _calculating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.calculate_rounded),
                        label: Text(_calculating ? 'Calculating…' : 'Calculate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.number,
    required this.amount,
    required this.deadline,
  });

  final int number;
  final int amount;
  final String deadline;

  String get _ordinal => switch (number) {
        1 => '1st',
        2 => '2nd',
        _ => '3rd',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_ordinal installment',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            '৳${amount.toString()}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Deadline: $deadline',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
