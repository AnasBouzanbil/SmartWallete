import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/money/display.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/logic/auth_state.dart';
import '../../auth/ui/recovery_code_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);
    final String name = auth.name.trim();
    final int balanceMinor = majorToMinor(auth.startingBalance);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space8,
            AppSpacing.space16,
            AppSpacing.space24,
          ),
          children: <Widget>[
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.isEmpty ? 'W' : name.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              name.isEmpty ? 'My wallet' : name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Starting balance ${formatMinor(balanceMinor)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Identity'),
            const SizedBox(height: AppSpacing.space8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.user,
                      color: colors.textPrimary,
                    ),
                    title: const Text('Display name'),
                    subtitle: Text(
                      name.isEmpty ? 'Not set' : name,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    trailing: Icon(
                      PhosphorIconsRegular.caretRight,
                      color: colors.textSecondary,
                    ),
                    onTap: () => _editName(context, ref, name),
                  ),
                  Divider(height: 1, color: colors.outline),
                  ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.coins,
                      color: colors.textPrimary,
                    ),
                    title: const Text('Starting balance'),
                    subtitle: Text(
                      formatMinor(balanceMinor),
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    trailing: Icon(
                      PhosphorIconsRegular.caretRight,
                      color: colors.textSecondary,
                    ),
                    onTap: () => _editStartingBalance(
                      context,
                      ref,
                      auth.startingBalance,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Security'),
            const SizedBox(height: AppSpacing.space8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.lockKey,
                      color: colors.textPrimary,
                    ),
                    title: const Text('Change password'),
                    subtitle: Text(
                      'Update the password used to unlock.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    trailing: Icon(
                      PhosphorIconsRegular.caretRight,
                      color: colors.textSecondary,
                    ),
                    onTap: () => _changePassword(context, ref),
                  ),
                  Divider(height: 1, color: colors.outline),
                  ListTile(
                    leading: Icon(
                      PhosphorIconsRegular.shieldCheck,
                      color: colors.textPrimary,
                    ),
                    title: const Text('New recovery code'),
                    subtitle: Text(
                      auth.hasRecoveryCode
                          ? 'Replace the code you saved at setup.'
                          : 'Create a recovery code for this wallet.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    trailing: Icon(
                      PhosphorIconsRegular.caretRight,
                      color: colors.textSecondary,
                    ),
                    onTap: () => _regenerateRecoveryCode(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              'Your password and recovery code stay on this phone. Changing '
              'the starting balance updates your total without deleting '
              'transactions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final String? next = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _NameDialog(initial: current),
    );
    if (next == null || !context.mounted) {
      return;
    }
    final bool ok =
        await ref.read(authControllerProvider.notifier).updateName(next);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Name updated.'
              : (ref.read(authControllerProvider).errorMessage ??
                  'Could not update name.'),
        ),
      ),
    );
  }

  Future<void> _editStartingBalance(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final _BalanceResult? result = await showDialog<_BalanceResult>(
      context: context,
      builder: (BuildContext context) => _BalanceDialog(initial: current),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .updateStartingBalance(
          password: result.password,
          startingBalance: result.balance,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Starting balance updated.'
              : (ref.read(authControllerProvider).errorMessage ??
                  'Could not update balance.'),
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final _PasswordChangeResult? result =
        await showDialog<_PasswordChangeResult>(
      context: context,
      builder: (BuildContext context) => const _ChangePasswordDialog(),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final bool ok =
        await ref.read(authControllerProvider.notifier).changePassword(
              currentPassword: result.current,
              newPassword: result.next,
            );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password updated.'
              : (ref.read(authControllerProvider).errorMessage ??
                  'Could not change password.'),
        ),
      ),
    );
  }

  Future<void> _regenerateRecoveryCode(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _ConfirmPasswordDialog(
        title: 'Confirm your password',
        confirmLabel: 'Continue',
      ),
    );
    if (password == null || password.isEmpty || !context.mounted) {
      return;
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Replace recovery code?'),
        content: const Text(
          'Your old recovery code will stop working. Make sure you can '
          'save the new one before continuing.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) {
      return;
    }

    final String? code = await ref
        .read(authControllerProvider.notifier)
        .regenerateRecoveryCode(password: password);
    if (!context.mounted) {
      return;
    }
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authControllerProvider).errorMessage ??
                'Could not create a recovery code.',
          ),
        ),
      );
      return;
    }
    await showRecoveryCodeDialog(context, code: code);
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Display name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Name',
          errorText: _error,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BalanceResult {
  const _BalanceResult({required this.balance, required this.password});

  final double balance;
  final String password;
}

class _BalanceDialog extends StatefulWidget {
  const _BalanceDialog({required this.initial});

  final double initial;

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  late final TextEditingController _balance = TextEditingController(
    text: _format(widget.initial),
  );
  final TextEditingController _password = TextEditingController();
  String? _balanceError;
  String? _passwordError;
  bool _obscure = true;

  @override
  void dispose() {
    _balance.dispose();
    _password.dispose();
    super.dispose();
  }

  String _format(double value) {
    final Money money = Money(majorToMinor(value));
    final int whole = money.minor ~/ 100;
    final int frac = money.minor % 100;
    if (frac == 0) {
      return '$whole';
    }
    return '$whole.${frac.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final Money? amount = Money.tryParse(_balance.text);
    final String password = _password.text;
    String? balanceError;
    String? passwordError;

    if (amount == null) {
      balanceError = 'Enter a number.';
    } else if (amount.isNegative) {
      balanceError = 'Balance cannot be negative.';
    }
    if (password.isEmpty) {
      passwordError = 'Enter your password.';
    }

    if (balanceError != null || passwordError != null) {
      setState(() {
        _balanceError = balanceError;
        _passwordError = passwordError;
      });
      return;
    }

    Navigator.of(context).pop(
      _BalanceResult(
        balance: amount!.minor / 100,
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Starting balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'This shifts your total balance. Transactions are not deleted.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.space16),
          TextField(
            controller: _balance,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount (${appCurrency.symbol})',
              errorText: _balanceError,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _passwordError,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PasswordChangeResult {
  const _PasswordChangeResult({
    required this.current,
    required this.next,
  });

  final String current;
  final String next;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _currentError;
  String? _nextError;
  String? _confirmError;
  bool _obscureCurrent = true;
  bool _obscureNext = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final String current = _current.text;
    final String next = _next.text;
    final String confirm = _confirm.text;
    String? currentError;
    String? nextError;
    String? confirmError;

    if (current.isEmpty) {
      currentError = 'Enter your current password.';
    }
    if (next.length < AuthController.minPasswordLength) {
      nextError =
          'At least ${AuthController.minPasswordLength} characters.';
    }
    if (confirm != next) {
      confirmError = 'Passwords do not match.';
    }

    if (currentError != null || nextError != null || confirmError != null) {
      setState(() {
        _currentError = currentError;
        _nextError = nextError;
        _confirmError = confirmError;
      });
      return;
    }

    Navigator.of(context).pop(
      _PasswordChangeResult(current: current, next: next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _current,
              autofocus: true,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Current password',
                errorText: _currentError,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(
                    _obscureCurrent
                        ? PhosphorIconsRegular.eye
                        : PhosphorIconsRegular.eyeSlash,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            TextField(
              controller: _next,
              obscureText: _obscureNext,
              decoration: InputDecoration(
                labelText: 'New password',
                errorText: _nextError,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureNext = !_obscureNext),
                  icon: Icon(
                    _obscureNext
                        ? PhosphorIconsRegular.eye
                        : PhosphorIconsRegular.eyeSlash,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            TextField(
              controller: _confirm,
              obscureText: _obscureNext,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                errorText: _confirmError,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog({
    required this.title,
    required this.confirmLabel,
  });

  final String title;
  final String confirmLabel;

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: _obscure,
        onSubmitted: (String v) => Navigator.of(context).pop(v),
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
