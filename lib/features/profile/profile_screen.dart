import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../services/user_repository.dart';
import '../../services/auth_repository.dart';
import '../../state/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userRepo = UserRepository();
  final _authRepo = AuthRepository();
  late TextEditingController _name, _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _name = TextEditingController(text: profile?.fullName ?? '');
    _phone = TextEditingController(text: profile?.phone ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      await _userRepo.updateMyProfile({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      await auth.refreshProfile();
      if (!mounted) return;
      showSnack(context, 'Profile updated', success: true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Update failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await _authRepo.resetPassword(email);
      if (!mounted) return;
      showSnack(context, 'Password reset email sent to $email', success: true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Could not send reset email');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      (profile?.fullName.isNotEmpty == true
                              ? profile!.fullName[0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (profile?.roleName != null)
                    StatusBadge(
                      status: profile!.roleSlug ?? '',
                      label: profile.roleName,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Account details'),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name *',
                      ),
                      validator: FieldValidators.requiredText,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: FieldValidators.optionalPhone,
                    ),
                    const SizedBox(height: 14),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Email'),
                      child: Text(profile?.email ?? '-'),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Reset password'),
                subtitle: const Text(
                  'We\u2019ll email you a secure reset link',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _sendPasswordReset(profile?.email),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  final confirmed = await confirmDialog(
                    context,
                    title: 'Sign out?',
                    message: 'You will need to sign in again.',
                    confirmLabel: 'Sign out',
                  );
                  if (confirmed) await auth.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
