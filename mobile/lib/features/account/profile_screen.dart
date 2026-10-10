import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';
import '../results/result_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  int revision = 0;
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) setState(() => revision++);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> editText({
    required String title,
    required String label,
    String initial = '',
    bool secret = false,
    String? explanation,
  }) async {
    final controller = TextEditingController(text: initial);
    bool visible = false;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(title),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (explanation != null) ...[
                Text(explanation),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: secret && !visible,
                maxLength: secret ? null : 80,
                autocorrect: !secret,
                enableSuggestions: !secret,
                decoration: InputDecoration(
                  labelText: label,
                  suffixIcon: secret
                      ? IconButton(
                          tooltip: visible ? 'Hide password' : 'Show password',
                          onPressed: () => update(() => visible = !visible),
                          icon: Icon(
                            visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: secret
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              onPressed: () {
                if (!secret || controller.text.isNotEmpty) {
                  Navigator.pop(dialogContext, controller.text);
                }
              },
              child: Text(secret ? 'Delete account' : 'Save name'),
            ),
          ],
        ),
      ),
    );
    // Let the closing route finish reading the field before disposing it.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  Future<void> updateUser(
    Json user, {
    String? name,
    bool? alerts,
    int? retention,
  }) async {
    await ref
        .read(apiProvider)
        .request(
          'PATCH',
          '/users/me',
          data: {
            'display_name': name ?? user['display_name'],
            'alerts_enabled': alerts ?? user['alerts_enabled'],
            'retention_days': retention ?? user['retention_days'],
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiProvider);
    final theme = ref.watch(themeProvider);
    return ApiPanel(
      key: ValueKey(revision),
      load: () => api.get('/users/me'),
      builder: (user) => PageBody(
        storageKey: 'profile',
        children: [
          const PageHeading(
            title: 'Your account',
            subtitle: 'Your preferences. Your privacy. Your control.',
          ),
          if (busy)
            Semantics(
              liveRegion: true,
              label: 'Saving account changes',
              child: const LinearProgressIndicator(),
            ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (user['display_name'] as String).isEmpty
                                ? 'Your Scan Shield account'
                                : user['display_name'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(user['email']),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      user['verified'] == true
                          ? Icons.verified_outlined
                          : Icons.schedule,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user['verified'] == true
                            ? 'Email verified'
                            : 'Email verification pending',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                SettingsRow(
                  icon: Icons.edit_outlined,
                  title: 'Display name',
                  subtitle: 'Choose how your account appears',
                  enabled: !busy,
                  onTap: () => run(() async {
                    final name = await editText(
                      title: 'Edit display name',
                      label: 'Display name',
                      initial: user['display_name'],
                    );
                    if (name != null) {
                      await updateUser(user, name: name);
                      if (context.mounted) {
                        showMessage(context, 'Display name saved.');
                      }
                    }
                  }),
                ),
              ],
            ),
          ),
          const SectionHeading('Preferences'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ThemeMode>(
                  initialValue: theme,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Appearance',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  items: ThemeMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(switch (mode) {
                            ThemeMode.system => 'Match device',
                            ThemeMode.light => 'Light',
                            ThemeMode.dark => 'Dark',
                          }),
                        ),
                      )
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeProvider.notifier).set(mode);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In-app risk alerts'),
                  subtitle: const Text(
                    'See alerts for risky scans when you use Scan Shield.',
                  ),
                  value: user['alerts_enabled'],
                  onChanged: busy
                      ? null
                      : (value) => run(() => updateUser(user, alerts: value)),
                ),
              ],
            ),
          ),
          const SectionHeading(
            'Data & privacy',
            subtitle: 'Manage what stays in your history.',
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('retention-$revision'),
                  initialValue: user['retention_days'],
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Keep scan history for',
                    prefixIcon: Icon(Icons.history),
                  ),
                  items:
                      ({
                            1,
                            7,
                            30,
                            90,
                            365,
                            user['retention_days'] as int,
                          }.toList()..sort())
                          .map(
                            (days) => DropdownMenuItem(
                              value: days,
                              child: Text(
                                '$days ${days == 1 ? 'day' : 'days'}',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: busy
                      ? null
                      : (value) => run(() async {
                          if (value == null ||
                              value == user['retention_days']) {
                            return;
                          }
                          if (!await confirm(
                            context,
                            'Change history retention?',
                            'Records older than $value days will be deleted. This also removes their linked feedback, reports and alerts.',
                            confirmLabel: 'Change retention',
                            destructive:
                                value < (user['retention_days'] as int),
                          )) {
                            return;
                          }
                          await updateUser(user, retention: value);
                          await api.clearCache();
                          if (context.mounted) {
                            showMessage(context, 'History retention updated.');
                          }
                        }),
                ),
                const SizedBox(height: 16),
                const Text(
                  'History keeps scores and general evidence, not your original messages or audio. Feedback and report comments are saved, so avoid sensitive details.',
                ),
                const Divider(height: 32),
                SettingsRow(
                  icon: Icons.ios_share,
                  title: 'Export my data',
                  subtitle: 'Get a copy of your account and scan records',
                  enabled: !busy,
                  onTap: () => run(() async {
                    final result = await api.get('/users/me/export');
                    await shareJson(result);
                  }),
                ),
                SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & permissions',
                  subtitle: 'How your content is processed',
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
          ),
          const SectionHeading('Security'),
          SurfaceCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.devices_outlined,
                  title: 'Sign out all devices',
                  subtitle: 'End every active session, including this one',
                  enabled: !busy,
                  onTap: () => run(() async {
                    if (!await confirm(
                      context,
                      'Sign out all devices?',
                      'You will need to sign in again on every device.',
                      confirmLabel: 'Sign out all devices',
                    )) {
                      return;
                    }
                    await api.request('POST', '/auth/revoke-all');
                    await api.clearSession();
                  }),
                ),
                SettingsRow(
                  icon: Icons.logout,
                  title: 'Sign out',
                  subtitle: 'Clear this device’s session and cached history',
                  enabled: !busy,
                  onTap: () => run(api.logout),
                ),
              ],
            ),
          ),
          const SectionHeading('Help & application'),
          SurfaceCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.help_outline,
                  title: 'Help, privacy & terms',
                  subtitle: 'Guidance for a more informed next step',
                  onTap: () => context.push('/help'),
                ),
                const SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Scan Shield',
                  subtitle: 'Version 0.1.0 · Scans only what you submit',
                ),
              ],
            ),
          ),
          const SectionHeading('Delete account'),
          SurfaceCard(
            child: SettingsRow(
              icon: Icons.delete_outline,
              title: 'Permanently delete my account',
              subtitle: 'Delete your account and all application records',
              danger: true,
              enabled: !busy,
              onTap: () => run(() async {
                final secret = await editText(
                  title: 'Delete account permanently?',
                  label: 'Password',
                  secret: true,
                  explanation:
                      'Your account, scan history, feedback, reports and alerts will be deleted. This cannot be undone. Enter your password to confirm.',
                );
                if (secret == null) return;
                await api.request(
                  'DELETE',
                  '/users/me',
                  data: {'password': secret},
                );
                await api.clearSession();
              }),
            ),
          ),
        ],
      ),
    );
  }
}
