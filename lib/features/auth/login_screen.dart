import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/common.dart';
import '../../services/auth_repository.dart';
import '../../state/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Mode { signIn, signUp, forgotPassword }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _submitting = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    if (_mode == _Mode.forgotPassword) {
      try {
        await AuthRepository().resetPassword(_email.text.trim());
        if (!mounted) return;
        showSnack(
          context,
          'Password reset email sent. Check your inbox.',
          success: true,
        );
        _setMode(_Mode.signIn);
      } catch (e) {
        if (!mounted) return;
        showError(context, e, prefix: 'Could not send reset email');
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = _mode == _Mode.signUp
        ? await auth.signUp(
            _email.text.trim(),
            _password.text,
            _fullName.text.trim(),
          )
        : await auth.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      showSnack(context, error, error: true);
    } else if (_mode == _Mode.signUp) {
      showSnack(
        context,
        'Account created. New users start as Sales Representative - an admin can promote you.',
        success: true,
      );
    }
  }

  void _setMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _obscurePassword = true;
    });
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  String get _title {
    switch (_mode) {
      case _Mode.signIn:
        return 'Welcome back';
      case _Mode.signUp:
        return 'Create your account';
      case _Mode.forgotPassword:
        return 'Reset your password';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _Mode.signIn:
        return 'Sign in to manage your sales workspace.';
      case _Mode.signUp:
        return 'Create a workspace profile for leads, deals, and follow-ups.';
      case _Mode.forgotPassword:
        return 'Enter your email and we will send a secure reset link.';
    }
  }

  String get _submitLabel {
    switch (_mode) {
      case _Mode.signIn:
        return 'Sign in';
      case _Mode.signUp:
        return 'Create account';
      case _Mode.forgotPassword:
        return 'Send reset link';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const Expanded(child: _BrandPanel()),
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : 20,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _AuthCard(
                        formKey: _formKey,
                        mode: _mode,
                        title: _title,
                        subtitle: _subtitle,
                        submitLabel: _submitLabel,
                        submitting: _submitting,
                        obscurePassword: _obscurePassword,
                        email: _email,
                        password: _password,
                        fullName: _fullName,
                        showMobileLogo: !wide,
                        onModeChanged: _setMode,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onSubmit: _submitting ? null : _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final _Mode mode;
  final String title;
  final String subtitle;
  final String submitLabel;
  final bool submitting;
  final bool obscurePassword;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController fullName;
  final bool showMobileLogo;
  final ValueChanged<_Mode> onModeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;

  const _AuthCard({
    required this.formKey,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    required this.submitting,
    required this.obscurePassword,
    required this.email,
    required this.password,
    required this.fullName,
    required this.showMobileLogo,
    required this.onModeChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showMobileLogo) ...[
                  const Center(child: _LogoMark(size: 64)),
                  const SizedBox(height: 18),
                ],
                if (mode != _Mode.forgotPassword) ...[
                  _ModeSelector(mode: mode, onChanged: onModeChanged),
                  const SizedBox(height: 28),
                ] else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onModeChanged(_Mode.signIn),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to sign in'),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Column(
                    key: ValueKey(mode),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (mode == _Mode.signUp) ...[
                        const _FieldLabel('Full name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: fullName,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            hintText: 'Enter full name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          validator: FieldValidators.requiredText,
                        ),
                        const SizedBox(height: 14),
                      ],
                      const _FieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: mode == _Mode.forgotPassword
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: FieldValidators.email,
                        onFieldSubmitted: (_) {
                          if (mode == _Mode.forgotPassword) onSubmit?.call();
                        },
                      ),
                      if (mode != _Mode.forgotPassword) ...[
                        const SizedBox(height: 14),
                        const _FieldLabel('Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: password,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: mode == _Mode.signUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              tooltip: obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: onTogglePassword,
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                              ? 'Minimum 6 characters'
                              : null,
                          onFieldSubmitted: (_) => onSubmit?.call(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (mode == _Mode.signIn) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => onModeChanged(_Mode.forgotPassword),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ] else
                  const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(submitLabel),
                  ),
                ),
                if (mode == _Mode.forgotPassword) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => onModeChanged(_Mode.signUp),
                      child: const Text('Create a new account'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_Mode>(
        showSelectedIcon: false,
        selected: {mode},
        segments: const [
          ButtonSegment<_Mode>(
            value: _Mode.signIn,
            label: Text('Sign in'),
          ),
          ButtonSegment<_Mode>(
            value: _Mode.signUp,
            label: Text('Sign up'),
          ),
        ],
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            );
          }),
        ),
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primaryDark),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _LogoMark(size: 58),
                SizedBox(width: 14),
                Text(
                  'Sales CRM',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'A focused workspace for leads, deals, and follow-ups.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: 34,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Keep the sales team moving with a clean pipeline, clear next steps, and real-time activity.',
              style: TextStyle(
                color: AppColors.textOnPrimaryMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 34),
            const Row(
              children: [
                Expanded(
                  child: _BrandMetric(
                    value: 'Leads',
                    label: 'Capture every inquiry',
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _BrandMetric(
                    value: 'Deals',
                    label: 'Track each next step',
                    color: AppColors.burgundy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _FeatureBullet(
              icon: Icons.person_add_alt_1_outlined,
              text: 'Capture and qualify new opportunities',
            ),
            const _FeatureBullet(
              icon: Icons.view_kanban_outlined,
              text: 'Move deals through every pipeline stage',
            ),
            const _FeatureBullet(
              icon: Icons.query_stats_rounded,
              text: 'Review performance without leaving the app',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _BrandMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BrandMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.overlayOnDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOnDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textOnPrimaryMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;

  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureBullet({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.overlayOnDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textOnPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
