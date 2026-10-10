import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Brand(),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(apiProvider).finishOnboarding();
            if (context.mounted) context.go('/auth');
          },
          child: const Text('Skip'),
        ),
      ],
    ),
    body: PageBody(
      maxWidth: 560,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/branding/icon.svg',
                width: 116,
                semanticsLabel: 'Scan Shield original shield',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final channel in ['sms', 'email', 'url', 'voice'])
                    Tooltip(
                      message: channelLabel(channel),
                      child: Icon(
                        channelIcon(channel),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const PageHeading(
          title: 'A moment to check.\nA safer next step.',
          eyebrow: 'WELCOME TO SCAN SHIELD',
          subtitle:
              'Make sense of suspicious messages, emails, links and voice transcripts.',
        ),
        const _IntroPoint(
          icon: Icons.touch_app_outlined,
          title: 'Choose what to check',
          body:
              'Paste text, share a link or submit a recording. Your inbox and calls are never monitored.',
        ),
        const _IntroPoint(
          icon: Icons.fact_check_outlined,
          title: 'Understand the warning signs',
          body:
              'See a risk score, the evidence behind it and practical next steps. A low score cannot guarantee safety.',
        ),
        const _IntroPoint(
          icon: Icons.lock_outline_rounded,
          title: 'Keep control of your data',
          body:
              'Submitted content goes to your backend for analysis. Raw messages are not saved in history; temporary audio is deleted after processing.',
        ),
        BusyButton(
          label: 'Get started',
          icon: Icons.arrow_forward_rounded,
          onPressed: () async {
            await ref.read(apiProvider).finishOnboarding();
            if (context.mounted) context.go('/auth');
          },
        ),
        TextButton(
          onPressed: () => context.push('/help'),
          child: const Text('Privacy & terms'),
        ),
      ],
    ),
  );
}

class _IntroPoint extends StatelessWidget {
  const _IntroPoint({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
      ),
    ],
  );
}
