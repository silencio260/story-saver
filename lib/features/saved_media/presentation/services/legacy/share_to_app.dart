import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/legacy_app_constants.dart';
import '../../../../analytics/data/services/firebase_analytics_service.dart';

void shareAppLink(BuildContext context) {
  AnalyticsService.logShareApp();

  Share.share(
    'Shared From WhatsApp Status Saver App @ ${AppConstants().GOOGLE_PLAY_STORE_LINK}',
  ).then((value) {
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(const SnackBar(content: Text("Image Sent")));
  });
}

void shareToWhatsApp(
  String message, {
  String? filePath,
  required BuildContext context,
}) async {
  final whatsappUrl = Uri.parse(
    "whatsapp://send?text=${Uri.encodeComponent(message)}",
  );

  if (await canLaunchUrl(whatsappUrl)) {
    print('Launching WhatsApp');
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Shared to WhatsApp")));
  } else {
    print('WhatsApp not found, using Share Plus');
    Share.share(message);
  }
}
