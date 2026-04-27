import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> copyTextToClipboard(String text) async {
  final normalized = text.trim();
  if (normalized.isEmpty) {
    return false;
  }

  try {
    await Clipboard.setData(ClipboardData(text: normalized));
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> openWhatsAppWeb() {
  return launchUrl(
    Uri.parse('https://web.whatsapp.com/'),
    mode: LaunchMode.externalApplication,
  );
}
