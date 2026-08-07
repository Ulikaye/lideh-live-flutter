import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_footer.dart';

enum StaticPageType { about, contact, terms, privacy, credits }

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
      case StaticPageType.credits:
        return 'Credits';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CenteredContent(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildBody(context),
              ),
            ),
            const AppFooter(),
          ],
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
      case StaticPageType.credits:
        return const _Credits();
    }
  }
}

class _About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.appName,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(AppStrings.tagline,
            style: const TextStyle(color: AppColors.textSecondary)),
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
        const SizedBox(height: 32),
        InkWell(
          onTap: () => context.go('/credits'),
          child: const Text(
            'Design credits',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline),
          ),
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
            subtitle: const Text('www.lidehtz@gmail.com'),
            onTap: () => launchUrl(Uri.parse('mailto:www.lidehtz@gmail.com.')),
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
        Text(body,
            style: const TextStyle(height: 1.6, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _Credits extends StatelessWidget {
  const _Credits();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credits', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        const Text(
          'Some icons used throughout this app are from Flaticon (flaticon.com), '
          'including icon packs by Magnific.',
          style: TextStyle(height: 1.6, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

const _termsBody = '''
Terms of Service

Last updated: August 2026 '''
    '''\nBy accessing or using LiDeH Live, you agree to comply with and be legally bound by these Terms of Service. If you do not agree with any part of these Terms, please do not use the platform. LiDeH Live provides a marketplace that connects musicians, instrumentalists, churches, event organizers, and other users for music-related bookings and instrument rental services. Users are responsible for providing accurate information when creating an account and for keeping their login credentials confidential. Users must be at least 18 years old to create an account as a musician or event organizer and are responsible for all activities conducted through their accounts. '''
    '''\n\nLiDeH Live facilitates connections between users but does not guarantee the quality, availability, conduct, or performance of any musician, instrumentalist, organizer, or other user. Booking and payment arrangements made through the platform are subject to the information and conditions agreed upon by the parties involved. Payments may be processed securely through AzamPay, our third-party payment provider, and payment-related disputes should be reported to LiDeH Live and, where appropriate, resolved between the relevant parties and payment provider. Organizers may cancel a booking up to 48 hours before the scheduled event for a full refund, excluding applicable payment-processing fees. Musicians may decline booking requests, while repeated cancellations, fraudulent activity, harassment, misleading information, or misuse of the platform may result in warnings, restrictions, suspension, or termination of an account. '''
    '''\n\nAll users are expected to use LiDeH Live respectfully, honestly, and lawfully. Users must not engage in harassment, fraud, impersonation, unauthorized activities, abusive behavior, or any activity that could harm other users or the operation of the platform. LiDeH Live reserves the right to investigate violations and take appropriate action, including removing content or suspending or terminating accounts. We may update these Terms of Service from time to time to reflect changes to our services, policies, or legal requirements. When significant changes are made, the updated version will be made available on the platform. Your continued use of LiDeH Live after changes are published constitutes acceptance of the updated Terms.
''';

const _privacyBody = '''
Privacy Policy

Last updated: August 2026 '''
    '''\nLiDeH Live respects your privacy and is committed to protecting the personal information you provide when using our platform. We may collect basic account and profile information such as your name, email address, phone number, location, profile information, and other details you voluntarily provide. This information is used to create and manage your account, connect musicians with churches and event organizers, facilitate bookings and instrument rentals, improve our services, and communicate important notifications. Payment transactions are processed securely through AzamPay, and LiDeH Live does not store your full payment or mobile-money credentials on its servers. We do not sell, rent, or trade your personal information to third parties for marketing purposes. '''
    '''\n\nWe take reasonable and industry-standard measures to protect your information against unauthorized access, alteration, disclosure, or destruction. However, no internet-based platform or electronic storage system can be guaranteed to be completely secure. Your information may be shared only when necessary to provide platform services, comply with applicable laws, prevent fraud or misuse, or protect the rights and safety of our users and the platform. By using LiDeH Live, you agree to the collection and use of your information as described in this Privacy Policy. You are responsible for keeping your account credentials confidential and should notify us if you believe your account has been accessed without authorization. '''
    '''\n\nYou have the right to request access to, correction of, or deletion of your personal information and account at any time, subject to applicable legal or operational requirements. If you no longer wish to use LiDeH Live, you may request that your account and associated personal data be deleted by contacting us. For questions, privacy concerns, or requests regarding your personal information, \nPlease contact lidehtz@gmail.com. We may update this Privacy Policy from time to time to reflect changes to our services, technology, or legal requirements, and the latest version will be made available on the LiDeH Live platform.
''';
