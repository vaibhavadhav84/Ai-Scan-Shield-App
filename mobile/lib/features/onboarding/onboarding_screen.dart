import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: 40),
          const Center(child: Brand(large: true)),
          Text(
            'A moment to check.\nA safer next step.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Text(
            'Analyze messages, emails, links and voice transcripts in one place. '
            'Understand the warning signs before you share information or make a payment.',
          ),
          const Notice(
            'You choose what to submit. Scan Shield does not monitor your inbox or calls.',
          ),
          const Notice(
            'Submitted content goes to your configured backend. Raw messages and transcripts '
            'are not retained in history. Uploaded audio is deleted after processing.',
          ),
          const Notice(
            'Detection can make mistakes. A low score does not guarantee safety.',
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(apiProvider).finishOnboarding();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Get started'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(apiProvider).finishOnboarding();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Skip introduction'),
          ),
          TextButton(
            onPressed: () => context.push('/help'),
            child: const Text('Privacy & terms'),
          ),
        ],
      ),
    ),
  );
}
