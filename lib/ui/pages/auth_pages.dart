import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import '../../bloc/app_states.dart';
import '../common_ui_components/auth_shell.dart';
import '../common_ui_components/submit_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    this.initialEmail,
    this.passwordResetSuccessful = false,
  });

  final String? initialEmail;
  final bool passwordResetSuccessful;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email.text =
        widget.initialEmail ?? context.read<AppBloc>().state.lastUsedEmail ?? '';
    if (widget.passwordResetSuccessful) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _message(context, 'Password reset successful.');
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    context.read<AppBloc>().add(SignInRequested(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
      listenWhen: (a, b) => a.action != b.action || a.actionStatus != b.actionStatus,
      listener: (context, state) {
        if (state.action != AppAction.signIn) return;
        if (state.actionStatus == AppActionStatus.failure) _message(context, state.errorMessage ?? 'Unable to sign in.');
        if (state.actionStatus == AppActionStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
        }
      },
      child: AuthShell(
        title: 'Welcome back',
        subtitle: 'Sign in to your CampusMate account.',
        children: [
          Form(
              key: _form,
              child: Column(children: [
                TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'University email',
                        prefixIcon: Icon(Icons.mail_outline_rounded)),
                    validator: _emailValidator),
                const SizedBox(height: 14),
                TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined))),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _submit()),
                const SizedBox(height: 20),
                SubmitButton(label: 'Sign in', onPressed: _submit),
              ])),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 18),
          Center(
              child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('New to UIU? Create an account'))),
        ],
      ));

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordResetEmailDialog(),
    );
    if (email == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PasswordRecoveryOtpPage(email: email),
      ),
    );
  }
}

class _PasswordResetEmailDialog extends StatefulWidget {
  const _PasswordResetEmailDialog();

  @override
  State<_PasswordResetEmailDialog> createState() =>
      _PasswordResetEmailDialogState();
}

class _PasswordResetEmailDialogState extends State<_PasswordResetEmailDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.requestPasswordReset &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pop(_email.text.trim());
          } else if (state.actionStatus == AppActionStatus.failure) {
            setState(() {
              _sending = false;
              _error = state.errorMessage ?? 'Unable to send a reset code.';
            });
          }
        },
        child: AlertDialog(
          title: const Text('Reset password'),
          content: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'If an account exists for this email, a recovery OTP will be sent.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: _emailValidator,
                  onFieldSubmitted: (_) => _send(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _sending ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send OTP'),
            ),
          ],
        ),
      );

  void _send() {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    context
        .read<AppBloc>()
        .add(PasswordResetOtpRequested(_email.text.trim()));
  }
}

class PasswordRecoveryOtpPage extends StatefulWidget {
  const PasswordRecoveryOtpPage({super.key, required this.email});

  final String email;

  @override
  State<PasswordRecoveryOtpPage> createState() =>
      _PasswordRecoveryOtpPageState();
}

class _PasswordRecoveryOtpPageState extends State<PasswordRecoveryOtpPage> {
  final _form = GlobalKey<FormState>();
  final _token = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            (current.action == AppAction.verifyPasswordRecoveryOtp ||
                current.action == AppAction.resendPasswordRecoveryOtp) &&
            (previous.action != current.action ||
                previous.actionStatus != current.actionStatus),
        listener: (context, state) {
          if (state.action == AppAction.resendPasswordRecoveryOtp) {
            if (state.actionStatus == AppActionStatus.pending) return;
            setState(() => _resending = false);
            if (state.actionStatus == AppActionStatus.success) {
              _startResendTimer();
            } else if (state.actionStatus == AppActionStatus.failure) {
              _message(context,
                  state.errorMessage ?? 'Unable to resend the recovery OTP.');
            }
          } else if (state.actionStatus == AppActionStatus.failure) {
            setState(() => _verifying = false);
            _message(context, 'The OTP is expired or incorrect. Please try again.');
          } else if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pushReplacement<void, void>(
              MaterialPageRoute<void>(
                builder: (_) => NewPasswordPage(email: widget.email),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Verify recovery code')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Enter the OTP sent to ${widget.email}.'),
                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: TextFormField(
                    controller: _token,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Six-digit OTP',
                      prefixIcon: Icon(Icons.password_rounded),
                    ),
                    validator: (value) =>
                        RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Enter the six-digit OTP',
                    onFieldSubmitted: (_) => _verify(),
                  ),
                ),
                const SizedBox(height: 12),
                SubmitButton(
                  label: _verifying ? 'Verifying…' : 'Verify OTP',
                  onPressed: _verify,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _seconds == 0 && !_resending ? _resend : null,
                    child: Text(
                      _resending
                          ? 'Sending OTP…'
                          : _seconds == 0
                              ? 'Resend OTP'
                              : 'Resend OTP in 00:${_seconds.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _verify() {
    if (!_form.currentState!.validate()) return;
    setState(() => _verifying = true);
    context.read<AppBloc>().add(PasswordRecoveryOtpVerified(
          email: widget.email,
          token: _token.text.trim(),
        ));
  }

  void _resend() {
    if (_seconds > 0 || _resending) return;
    setState(() => _resending = true);
    context.read<AppBloc>().add(PasswordRecoveryOtpResent(widget.email));
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }
}

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.updatePassword &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.failure) {
            setState(() => _saving = false);
            _message(context, state.errorMessage ?? 'Unable to update password.');
          } else if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (_) => SignInPage(
                  initialEmail: widget.email,
                  passwordResetSuccessful: true,
                ),
              ),
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Choose a new password')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.length < 8)
                                ? 'Use at least 8 characters'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Passwords do not match'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SubmitButton(
                  label: _saving ? 'Updating…' : 'Update password',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    context.read<AppBloc>().add(RecoveryPasswordUpdated(_password.text));
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  XFile? _picture;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickPicture() async {
    final picture = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1200);
    if (picture != null && mounted) setState(() => _picture = picture);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    context.read<AppBloc>().add(SignUpRequested(
      email: _email.text.trim(),
      password: _password.text,
      fullName: _name.text.trim(),
      studentId: _studentId.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
      listenWhen: (a, b) => a.action != b.action || a.actionStatus != b.actionStatus,
      listener: (context, state) {
        if (state.action != AppAction.signUp) return;
        if (state.actionStatus == AppActionStatus.failure) {
          if (state.errorMessage == 'Account already Exists') {
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Account already Exists'),
                content: const Text(
                    'An account with this email address already exists.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext)
                        .pushNamedAndRemoveUntil('/signin', (route) => false),
                    child: const Text('Proceed to Login'),
                  ),
                ],
              ),
            );
          } else {
            _message(context,
                state.errorMessage ?? 'Unable to create account.');
          }
        }
        if (state.actionStatus == AppActionStatus.success) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VerifyEmailPage(email: _email.text.trim(), picturePath: _picture?.path)));
        }
      },
      child: AuthShell(
        title: 'Make campus yours',
        subtitle: 'Create your student account to get started.',
        children: [
          Form(
              key: _form,
              child: Column(children: [
                Center(
                    child: GestureDetector(
                        onTap: _pickPicture,
                        child: CircleAvatar(
                            radius: 39,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: _picture == null
                                ? null
                                : FileImage(File(_picture!.path)),
                            child: _picture == null
                                ? const Icon(Icons.add_a_photo_outlined,
                                    size: 28)
                                : null))),
                const SizedBox(height: 8),
                const Text('Add a profile picture (optional)'),
                const SizedBox(height: 18),
                TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded)),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your full name'
                        : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _studentId,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Student ID',
                        prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) {
                      final studentId = v?.trim() ?? '';
                      if (!RegExp(r'^\d{9,10}$').hasMatch(studentId)) {
                        return 'Student ID must contain 9 or 10 digits';
                      }
                      final emailLocalPart = _email.text.trim().split('@').first;
                      if (!emailLocalPart.endsWith(studentId.substring(3))) {
                        return 'Id did not match the email';
                      }
                      return null;
                    }),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded)),
                    validator: _signupEmailValidator),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined))),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Use at least 8 characters'
                        : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match'
                        : null),
                const SizedBox(height: 20),
                SubmitButton(label: 'Create account', onPressed: _submit),
              ])),
          const SizedBox(height: 14),
          Center(
              child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/signin'),
                  child: const Text('Already have an account? Sign in'))),
        ],
      ));
}

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email, this.picturePath});
  final String email;
  final String? picturePath;
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _saveAvatarAfterVerification() async {
      if (widget.picturePath != null) {
        try {
          final userId = Supabase.instance.client.auth.currentUser!.id;
          final file = File(widget.picturePath!);
          final ext = widget.picturePath!.contains('.')
              ? widget.picturePath!.split('.').last.toLowerCase()
              : 'jpg';
          final path = '$userId/avatar.$ext';
          final storage =
              Supabase.instance.client.storage.from('profile-avatars');
          await storage.upload(path, file,
              fileOptions: const FileOptions(upsert: true));
          await Supabase.instance.client
              .from('campusmate_profiles')
              .update({'avatar_path': path}).eq('user_id', userId);
          await Supabase.instance.client.auth
              .updateUser(UserAttributes(data: {'avatar_path': path}));
        } catch (e) {
          if (mounted) {
            _message(context,
                'Email verified, but the profile photo was not saved: ${_authMessage(e)}');
          }
        }
      }
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
  }

  void _verify() => context.read<AppBloc>().add(VerifySignupOtpRequested(widget.email, _code.text));
  void _resend() {
    setState(() => _resending = true);
    context.read<AppBloc>().add(ResendSignupOtpRequested(widget.email));
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
      listenWhen: (a, b) => a.action != b.action || a.actionStatus != b.actionStatus,
      listener: (context, state) {
        if (state.action == AppAction.verifyOtp) {
          if (state.actionStatus == AppActionStatus.success) _saveAvatarAfterVerification();
          if (state.actionStatus == AppActionStatus.failure) _message(context, state.errorMessage ?? 'Unable to verify email.');
        } else if (state.action == AppAction.resendOtp) {
          if (state.actionStatus == AppActionStatus.pending) return;
          if (mounted) setState(() => _resending = false);
          if (state.actionStatus == AppActionStatus.success) _startTimer();
          if (state.actionStatus == AppActionStatus.failure) _message(context, state.errorMessage ?? 'Unable to resend code.');
        }
      },
      child: AuthShell(
          title: 'Check your inbox',
          subtitle:
              'We sent a six-digit code to ${widget.email}. Enter it below to verify your account.',
          children: [
            TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                    labelText: 'Verification code', counterText: '')),
            const SizedBox(height: 18),
            SubmitButton(label: 'Verify email', onPressed: _verify),
            const SizedBox(height: 12),
            Center(
                child: TextButton(
                    onPressed: _seconds == 0 && !_resending ? _resend : null,
                    child: Text(_resending
                        ? 'Sending code…'
                        : _seconds == 0
                            ? 'Resend OTP'
                            : 'Resend OTP in 00:${_seconds.toString().padLeft(2, '0')}'))),
          ]));
}

String? _emailValidator(String? value) => value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Enter a valid email address'
    : null;

String? _signupEmailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }
  if (!email.toLowerCase().endsWith('.uiu.ac.bd')) {
    return 'Use your UIU email ending in .uiu.ac.bd';
  }
  return null;
}

String _authMessage(Object error) => error is AuthException
    ? error.message
    : error.toString().replaceFirst('Exception: ', '');
void _message(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
