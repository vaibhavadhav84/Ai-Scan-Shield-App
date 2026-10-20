import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Widget topic(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> paragraphs,
  }) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      key: PageStorageKey('help-$title'),
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: Text(paragraphs[i]),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & privacy')),
    body: PageBody(
      storageKey: 'help',
      children: [
        const PageHeading(
          title: 'A clearer next step',
          subtitle:
              'Understand your results, protect your privacy and stay in control.',
          eyebrow: 'SCAN SHIELD GUIDE',
        ),
        const Notice(
          'Scan Shield checks the content you choose to submit. It does not watch your messages, calls or mailbox.',
          icon: Icons.shield_outlined,
        ),
        const SectionHeading('Using Scan Shield'),
        topic(
          context,
          icon: Icons.manage_search_outlined,
          title: 'How to check suspicious content',
          paragraphs: const [
            'Open Scan and choose text, email, link, voice or call details. Paste content or use a supported import, then start the analysis.',
            'Read the risk level, score and explanation together. Review the evidence and recommended precautions before acting. History lets you revisit results, give feedback or submit an internal report.',
          ],
        ),
        topic(
          context,
          icon: Icons.rule_outlined,
          title: 'What your risk result means',
          paragraphs: const [
            'Safe: few or no supported risk indicators were found. This does not guarantee that a message, person or link is legitimate.',
            'Suspicious: some indicators deserve a closer look. Verify the request through a channel you already trust.',
            'High Risk: strong indicators were found. Pause before sharing information, paying or following instructions.',
            'The score is an indicator out of 100, not a proven probability of fraud. Read the limitations: unavailable checks are not successful checks.',
          ],
        ),
        topic(
          context,
          icon: Icons.lightbulb_outline,
          title: 'Simple scam precautions',
          paragraphs: const [
            'Keep OTPs, PINs and passwords private. Pause if someone pressures you to act or pay quickly.',
            'Contact a sender using independently trusted contact details. Do not install remote-access software at a stranger’s request.',
            'A padlock or HTTPS connection does not prove a site is trustworthy. You do not need to open a suspicious link to submit it for analysis.',
          ],
        ),
        const SectionHeading('Privacy & permissions'),
        topic(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'How your data is handled',
          paragraphs: const [
            'Submitted content is transmitted to the Scan Shield server for analysis. Original messages and transcripts are processed without being saved in history. Temporary uploaded audio is deleted after processing.',
            'Voice uploads require a speech model configured on that server. URLs are sent to the optional reputation provider only when you consent for that scan and the provider is available.',
            'Your account email, password hash, scores, general evidence and feedback/report comments are stored. Avoid sensitive information in comments.',
            'History defaults to 30 days. You can change retention, export records or delete your account from Profile. Android and iOS history caches last up to 24 hours and are cleared on sign-out or deletion.',
          ],
        ),
        topic(
          context,
          icon: Icons.mic_none_outlined,
          title: 'Microphone & file access',
          paragraphs: const [
            'Microphone permission is requested when you choose to record. Obtain permission from anyone being recorded. Manage microphone access in your device settings.',
            'You choose files using the system picker. Scan Shield does not request your SMS inbox, contacts, call logs or background call-recording access.',
            'Audio upload supports PCM WAV files within the limits shown in the scanner. If speech processing is unavailable, you can paste a transcript instead.',
          ],
        ),
        const SectionHeading('Connection & support'),
        topic(
          context,
          icon: Icons.wifi_off_outlined,
          title: 'Offline or a check is unavailable',
          paragraphs: const [
            'New scans need a connection to the Scan Shield server. If a scan fails, keep your input and try again when the connection returns. Cached history is labeled offline.',
            'Some checks depend on services enabled by your operator. Voice upload needs a speech model, password recovery needs email delivery, and URL reputation needs a provider. Missing checks are explained with the result.',
            'No support address is configured for this version. For account or service help, contact the person operating your Scan Shield service.',
          ],
        ),
        topic(
          context,
          icon: Icons.flag_outlined,
          title: 'Feedback & internal reports',
          paragraphs: const [
            'Use feedback on a result to say whether it seems correct. You can add a short optional comment. Feedback does not immediately change the result or train a model.',
            'Reports go to this application’s internal review queue. They are not submitted to a government or cybercrime service. Review the result first and keep private details out of your report.',
          ],
        ),
        topic(
          context,
          icon: Icons.description_outlined,
          title: 'Terms & service limitations',
          paragraphs: const [
            'This development version provides risk indicators and can make mistakes. It does not guarantee fraud prevention or verify identities. Independently verify sensitive actions.',
            'Submit only content you are entitled to analyze and obtain recording consent. Privacy and terms for this deployment are drafts until reviewed and published by the service operator.',
          ],
        ),
      ],
    ),
  );
}
