import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void shareToWhatsApp(String message, {String? filePath, required BuildContext context}) async {
  final whatsappUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(message)}");

  if (await canLaunchUrl(whatsappUrl)) {
    print('Launching WhatsApp');
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shared to WhatsApp")),
    );
  } else {
    print('WhatsApp not found, using Share Plus');
    Share.share(message);
  }
}
