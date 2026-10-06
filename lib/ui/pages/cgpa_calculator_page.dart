import 'package:flutter/material.dart';

import '../common_ui_components/input_surface.dart';

class CgpaCalculatorPage extends StatefulWidget {
  const CgpaCalculatorPage({super.key});

  @override
  State<CgpaCalculatorPage> createState() => _CgpaCalculatorPageState();
}

class _CgpaCalculatorPageState extends State<CgpaCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _cgpaController = TextEditingController();
  final _completedCreditsController = TextEditingController();
  final List<_CourseControllers> _courses = [];
  String? _courseLimitMessage;

  double get _plannedCredits => _courses.fold(
        0,
        (sum, course) => sum + (double.tryParse(course.credits.text) ?? 0),
      );

  @override
  void dispose() {
    _cgpaController.dispose();
    _completedCreditsController.dispose();
    for (final course in _courses) {
      course.dispose();
    }
    super.dispose();
  }

  void _addCourse() {
    FocusScope.of(context).unfocus();
    setState(() {
      _courseLimitMessage = null;
      if (_courses.isNotEmpty && !_courseIsComplete(_courses.last)) {
        _courseLimitMessage = 'Enter course credits and expected GPA first.';
        return;
      }
      if (_plannedCredits >= 16) {
        _courseLimitMessage = 'The total course credits cannot exceed 16.';
        return;
      }
      _courses.add(_CourseControllers());
    });
  }

  bool _courseIsComplete(_CourseControllers course) =>
      course.credits.text.trim().isNotEmpty && course.gpa.text.trim().isNotEmpty;

  String? _validateNumber(String? value,
      {required String label, required double minimum, double? maximum}) {
    final text = value?.trim() ?? '';
    final parsed = double.tryParse(text);
    if (text.isEmpty || parsed == null || !parsed.isFinite) {
      return 'Enter $label';
    }
    if (parsed < minimum || (maximum != null && parsed > maximum)) {
      return maximum == null
          ? '$label must be at least ${_formatNumber(minimum)}'
          : '$label must be ${_formatNumber(minimum)}–${_formatNumber(maximum)}';
    }
    return null;
  }

  String _formatNumber(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  void _calculate() {
    FocusScope.of(context).unfocus();
    setState(() => _courseLimitMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final currentCgpa = double.parse(_cgpaController.text.trim());
    final completedCredits = double.parse(_completedCreditsController.text.trim());
    final plannedCredits = _plannedCredits;
    if (completedCredits + plannedCredits <= 0) {
      setState(() => _courseLimitMessage = 'Add completed credits or course credits to calculate CGPA.');
      return;
    }

    final currentPoints = currentCgpa * completedCredits;
    final coursePoints = _courses.fold<double>(
      0,
      (sum, course) =>
          sum + double.parse(course.gpa.text.trim()) * double.parse(course.credits.text.trim()),
    );
    final result = (currentPoints + coursePoints) / (completedCredits + plannedCredits);
    _showResult(result);
  }

  void _showResult(double cgpa) {
    final (comment, color) = switch (cgpa) {
      <= 1 => ('Too bad', Colors.red),
      <= 2 => ('Needs Improvement', Colors.orange),
      <= 3 => ('Average', Colors.amber),
      <= 3.5 => ('Good performance keep it up', Colors.green),
      < 4 => ('Excellent Performance!!', Colors.blue),
      _ => ('Unbelievable Performance!!! Touch some grass bro!', Colors.blue),
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Calculated CGPA'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cgpa.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                comment,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('CGPA Calculator'),
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
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  children: [
                    _numberField(
                      controller: _cgpaController,
                      label: 'Current CGPA',
                      hint: 'For example, 3.50',
                      icon: Icons.school_outlined,
                      validator: (value) => _validateNumber(
                        value,
                        label: 'a CGPA',
                        minimum: 0,
                        maximum: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _numberField(
                      controller: _completedCreditsController,
                      label: 'Currently completed credits',
                      hint: 'For example, 45',
                      icon: Icons.credit_score_outlined,
                      validator: (value) => _validateNumber(
                        value,
                        label: 'completed credits',
                        minimum: 0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (var index = 0; index < _courses.length; index++) ...[
                      _courseFields(index, _courses[index]),
                      const SizedBox(height: 16),
                    ],
                    if (_courseLimitMessage != null) ...[
                      Text(
                        _courseLimitMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: _addCourse,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a course'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_rounded),
                        label: const Text('Calculate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) => InputSurface(
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          validator: validator,
        ),
      );

  Widget _courseFields(int index, _CourseControllers course) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course ${index + 1}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _numberField(
                  controller: course.credits,
                  label: 'Course credits',
                  hint: '1–3',
                  icon: Icons.menu_book_outlined,
                  validator: (value) => _validateNumber(
                    value,
                    label: 'course credits',
                    minimum: 1,
                    maximum: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: course.gpa,
                  label: 'Expected GPA',
                  hint: '0–4',
                  icon: Icons.grade_outlined,
                  validator: (value) => _validateNumber(
                    value,
                    label: 'expected GPA',
                    minimum: 0,
                    maximum: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}

class _CourseControllers {
  final credits = TextEditingController();
  final gpa = TextEditingController();

  void dispose() {
    credits.dispose();
    gpa.dispose();
  }
}
