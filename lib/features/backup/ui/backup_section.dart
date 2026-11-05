import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/logic/auth_state.dart';
import '../../transactions/logic/transaction_providers.dart';
import '../data/backup_codec.dart';
import '../data/backup_models.dart';
import '../logic/backup_providers.dart';

class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _includePhotos = true;
  bool _exporting = false;
  bool _importing = false;

  bool get _busy => _exporting || _importing;

  Future<void> _export() async {
    if (_busy) {
      return;
    }

    final AuthState auth = ref.read(authControllerProvider);
    final BackupProfile profile = BackupProfile(
      name: auth.name.trim().isEmpty ? 'My wallet' : auth.name,
      startingBalanceMinor: majorToMinor(auth.startingBalance),
    );

    setState(() => _exporting = true);
    try {
      final BackupDocument document = await ref
          .read(backupServiceProvider)
          .export(profile: profile, includePhotos: _includePhotos);
      final String json = BackupCodec.encode(document);
      final bool saved = await ref
          .read(backupFileServiceProvider)
          .saveJson(
            fileName: _fileName(),
            bytes: Uint8List.fromList(utf8.encode(json)),
          );
      if (!mounted) {
        return;
      }
      if (saved) {
        _showMessage('Backup saved.');
      }
    } on BackupException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not create the backup.');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _import() async {
    if (_busy) {
      return;
    }

    final Uint8List? bytes;
    try {
      bytes = await ref.read(backupFileServiceProvider).pickJson();
    } on BackupException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
      return;
    }
    if (bytes == null || !mounted) {
      return;
    }

    final BackupDocument document;
    try {
      document = BackupCodec.decode(utf8.decode(bytes));
    } on BackupException catch (error) {
      _showMessage(error.message);
      return;
    } on FormatException {
      _showMessage('This file is not valid UTF-8 JSON.');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Replace all data?'),
        content: Text(
          'This backup contains ${document.summary}.\n\n'
          'Importing it will permanently replace everything currently in '
          'your wallet.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _importing = true);
    bool profileRestored = true;
    try {
      final BackupImportResult result = await ref
          .read(backupServiceProvider)
          .import(document);
      ref.invalidate(defaultAccountProvider);
      try {
        await ref
            .read(authControllerProvider.notifier)
            .applyBackupProfile(
              name: document.profile.name,
              startingBalance: document.profile.startingBalanceMinor / 100,
            );
      } catch (_) {
        profileRestored = false;
      }
      if (!mounted) {
        return;
      }
      if (!result.receiptsRestored) {
        _showMessage(
          'Data imported, but receipt photos could not be restored.',
        );
      } else if (!profileRestored) {
        _showMessage('Data imported, but the profile could not be restored.');
      } else {
        _showMessage('Backup imported.');
      }
    } on BackupException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not import the backup.');
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  String _fileName() {
    final DateTime now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'smart-wallet-backup-'
        '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.json';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_busy) ...<Widget>[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.space16),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(PhosphorIconsRegular.fileArrowUp, color: colors.accent),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Export',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Save your accounts, transactions, debts and profile as a '
                'JSON file. Your password is never included.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              SwitchListTile(
                value: _includePhotos,
                onChanged: _busy
                    ? null
                    : (bool value) => setState(() => _includePhotos = value),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: colors.accent,
                title: const Text('Include receipt photos'),
                subtitle: const Text(
                  'Photos make the backup larger but restore them too.',
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              PrimaryButton(
                label: _exporting ? 'Exporting...' : 'Export JSON',
                onPressed: _busy ? null : _export,
                icon: PhosphorIconsRegular.fileArrowUp,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    PhosphorIconsRegular.fileArrowDown,
                    color: colors.expense,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Import',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Restore a Smart Wallet backup. Importing replaces all '
                'current data, so export first if you are unsure.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              PrimaryButton(
                label: _importing ? 'Importing...' : 'Import JSON',
                onPressed: _busy ? null : _import,
                icon: PhosphorIconsRegular.fileArrowDown,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
