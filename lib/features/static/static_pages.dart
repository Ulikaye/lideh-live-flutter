import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';

enum StaticPageType { about, contact, terms, privacy }

class StaticPage extends StatelessWidget {
  final StaticPageType type;
  const StaticPage({super.key, required this.type});

  String get _title {
    switch (type) {
      case StaticPageType.about:
        return 'About Us';
      case StaticPageType.contact:
        return 'Contact Us';
      case StaticPageType.terms:
        return 'Terms of Service';
      case StaticPageType.privacy:
        return 'Privacy Policy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        child: CenteredContent(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (type) {
      case StaticPageType.about:
        return _About();
      case StaticPageType.contact:
        return const _Contact();
      case StaticPageType.terms:
        return _StaticText(title: 'Terms of Service', body: _termsBody);
      case StaticPageType.privacy:
        return _StaticText(title: 'Privacy Policy', body: _privacyBody);
    }
  }
}

class _About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.appName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(AppStrings.tagline, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        const Text(
          'LiDeH Live connects talented gospel musicians with churches, ministries, and event '
          'organizers who need live music for their services and events. Musicians build a public '
          'profile showcasing their skills, experience, and sample performances, while organizers '
          'browse the directory, filter by location and skill, and send booking requests directly '
          'through the platform.\n\n'
          'Every completed booking can be reviewed, helping new organizers choose with confidence '
          'and giving musicians a track record that grows with every event they play.',
          style: TextStyle(height: 1.6),
        ),
      ],
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Get in Touch', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.primary),
            title: const Text('Email'),
            subtitle: const Text('support@lidehlive.com'),
            onTap: () => launchUrl(Uri.parse('mailto:support@lidehlive.com')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            title: const Text('Help Center'),
            subtitle: const Text('Frequently asked questions'),
          ),
        ),
      ],
    );
  }
}

class _StaticText extends StatelessWidget {
  final String title;
  final String body;
  const _StaticText({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Text(body, style: const TextStyle(height: 1.6, color: AppColors.textPrimary)),
      ],
    );
  }
}

const _termsBody = '''
Placeholder Terms of Service.

Replace this text with your organization's actual terms before launch. At minimum, cover: '''
    '''account eligibility, booking and cancellation policies, payment handling (if any occurs '''
    '''outside the platform), content ownership for uploaded media, and dispute resolution between '''
    '''musicians and organizers.
''';

const _privacyBody = '''
Placeholder Privacy Policy.

Replace this text with your organization's actual policy before launch. At minimum, cover: '''
    '''what personal data is collected (profile info, booking details, uploaded photos/videos), '''
    '''how Firebase Authentication, Firestore, and Storage process that data, retention and deletion '''
    '''practices, and how users can request account/data deletion.
''';
