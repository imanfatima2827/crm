import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common.dart';

Future<void> launchPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone.trim());
  if (!await launchUrl(uri)) {
    if (context.mounted) {
      showSnack(context, 'Could not open dialer', error: true);
    }
  }
}

Future<void> launchEmail(BuildContext context, String? email) async {
  if (email == null || email.trim().isEmpty) {
    return;
  }
  final uri = Uri(scheme: 'mailto', path: email.trim());
  if (!await launchUrl(uri)) {
    if (context.mounted) {
      showSnack(context, 'Could not open mail app', error: true);
    }
  }
}

Future<void> launchMaps(BuildContext context, String address) async {
  if (address.trim().isEmpty) {
    return;
  }
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      showSnack(context, 'Could not open maps', error: true);
    }
  }
}

/// Small row of contact quick-actions (call / email), used on lead &
/// customer detail screens.
class ContactQuickActions extends StatelessWidget {
  final String? phone;
  final String? email;
  const ContactQuickActions({super.key, this.phone, this.email});

  @override
  Widget build(BuildContext context) {
    if ((phone == null || phone!.isEmpty) &&
        (email == null || email!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      children: [
        if (phone != null && phone!.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => launchPhone(context, phone),
            icon: const Icon(Icons.call_outlined, size: 16),
            label: const Text('Call'),
          ),
        if (email != null && email!.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => launchEmail(context, email),
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Email'),
          ),
      ],
    );
  }
}
