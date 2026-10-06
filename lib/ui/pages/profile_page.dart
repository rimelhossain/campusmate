import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import '../../bloc/app_states.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _form = GlobalKey<FormState>();
  XFile? _photo;
  String? _avatarUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(ProfileLoadRequested());
  }

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _setProfile(Map<String, dynamic>? row) async {
      if (row != null) {
        _name.text = row['full_name'] as String? ?? '';
        _studentId.text = row['student_id'] as String? ?? '';
        final path = row['avatar_path'] as String?;
        if (path != null && path.isNotEmpty) {
          _avatarUrl = await Supabase.instance.client.storage
              .from('profile-avatars')
              .createSignedUrl(path, 3600);
        }
      }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1200);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<AppBloc>();
    try {
      if (_photo != null) {
        final uid = Supabase.instance.client.auth.currentUser!.id;
        final ext = _photo!.name.contains('.')
            ? _photo!.name.split('.').last.toLowerCase()
            : 'jpg';
        final path = '$uid/avatar.$ext';
        final storage =
            Supabase.instance.client.storage.from('profile-avatars');
        await storage.upload(path, File(_photo!.path),
            fileOptions: const FileOptions(upsert: true));
        _avatarUrl = path;
      }
      if (!mounted) return;
      final currentPath = Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_path'] as String?;
      bloc.add(ProfileUpdateRequested(fullName: _name.text, studentId: _studentId.text, avatarPath: _photo == null ? currentPath : _avatarUrl));
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeMode = context.select((AppBloc bloc) => bloc.state.themeMode);
    return BlocListener<AppBloc, AppState>(
      listenWhen: (a,b) => a.action != b.action || a.actionStatus != b.actionStatus,
      listener: (context, state) {
        if (state.action == AppAction.loadProfile) {
          if (state.actionStatus == AppActionStatus.success) _setProfile(state.profile);
          if (state.actionStatus == AppActionStatus.failure) { setState(() => _loading = false); _snack(state.errorMessage ?? 'Could not load profile.'); }
        } else if (state.action == AppAction.updateProfile) {
          setState(() => _saving = state.actionStatus == AppActionStatus.pending);
          if (state.actionStatus == AppActionStatus.success) {
            _avatarUrl = state.profile?['avatar_path'] as String?;
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
              Supabase.instance.client.storage.from('profile-avatars').createSignedUrl(_avatarUrl!, 3600).then((url) { if (mounted) setState(() => _avatarUrl = url); });
            }
            setState(() => _photo = null);
            _snack('Profile saved');
          }
          if (state.actionStatus == AppActionStatus.failure) _snack(state.errorMessage ?? 'Could not save profile.');
        } else if (state.action == AppAction.signOut && state.actionStatus == AppActionStatus.success) {
          Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
        } else if (state.action == AppAction.signOut && state.actionStatus == AppActionStatus.failure) {
          _snack(state.errorMessage ?? 'Could not log out.');
        }
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                  key: _form,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                      children: [
                        Center(
                            child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                          radius: 48,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          foregroundImage: _photo != null
                                              ? FileImage(File(_photo!.path))
                                              : (_avatarUrl == null
                                                  ? null
                                                  : NetworkImage(_avatarUrl!)),
                                          child: _photo == null &&
                                                  _avatarUrl != null
                                              ? null
                                              : Text(
                                                  (_name.text.isEmpty
                                                          ? 'U'
                                                          : _name.text
                                                              .trim()[0])
                                                      .toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium)),
                                      CircleAvatar(
                                          radius: 17,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          child: const Icon(Icons.edit_rounded,
                                              size: 17, color: Colors.white))
                                    ]))),
                        const SizedBox(height: 10),
                        const Center(child: Text('Tap to change picture')),
                        const SizedBox(height: 26),
                        TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded)),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name cannot be empty'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _studentId,
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: 'Student ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                                helperText:
                                    'Contact support if this needs to be corrected.')),
                        const SizedBox(height: 14),
                        TextFormField(
                            initialValue: user?.email ?? '',
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded))),
                        const SizedBox(height: 14),
                        Card(
                          child: SwitchListTile.adaptive(
                            secondary: Icon(themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded),
                            title: const Text('Dark mode'),
                            subtitle: const Text('Use a dark appearance'),
                            value: themeMode == ThemeMode.dark,
                            onChanged: (enabled) => context.read<AppBloc>().add(
                              ThemeModeChanged(
                                enabled ? ThemeMode.dark : ThemeMode.light,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Save changes'))),
                        const SizedBox(height: 38),
                        OutlinedButton.icon(
                            onPressed: () => context.read<AppBloc>().add(SignOutRequested()),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log out'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                padding: const EdgeInsets.all(14))),
                      ]))),
    ));
  }
}
