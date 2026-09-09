import 'package:flutter/material.dart';
import 'package:genrevibes_app_links/genrevibes_app_links.dart';

import '../../../../../container_injector.dart';

/// Opens WhatsApp with [message] prefilled, falling back to the share sheet.
///
/// The deep link goes through the kit's [LinkOpener] rather than `url_launcher`
/// directly, so this file no longer knows which package launches a URI. The
/// fallback is deliberate and unchanged: `whatsapp://` fails on a device without
/// WhatsApp installed, and a status-saver user without WhatsApp still has
/// somewhere useful to send the file.
Future<void> shareToWhatsApp(
  String message, {
  String? filePath,
  required BuildContext context,
}) async {
  final opener = sl<LinkOpener>();
  final whatsapp = Uri.parse(
    'whatsapp://send?text=${Uri.encodeComponent(message)}',
  );

  final launched = await opener.openUrl(whatsapp);
  final ok = launched.fold(onSuccess: (_) => true, onFailure: (_) => false);

  if (ok) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shared to WhatsApp')));
    }
    return;
  }

  await opener.share(text: message);
}
