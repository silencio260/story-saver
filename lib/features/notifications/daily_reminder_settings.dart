import 'package:flutter/material.dart';

import 'daily_reminder_service.dart';
import 'notification_strings.dart';

class DailyReminderSettings extends StatelessWidget {
  const DailyReminderSettings({super.key, required this.service});
  final DailyReminderService service;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    builder: (context, _) {
      if (!service.supported) return const SizedBox.shrink();
      return Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text(NotificationStrings.settingsTitle),
              subtitle: Text(
                service.enabled
                    ? NotificationStrings.schedule
                    : NotificationStrings.disabled,
              ),
              value: service.enabled,
              onChanged:
                  service.busy || !service.ready ? null : service.setEnabled,
            ),
            if (service.enabled &&
                (!service.allowed || !service.channelEnabled))
              ListTile(
                subtitle: const Text(NotificationStrings.blocked),
                trailing: TextButton(
                  onPressed: service.busy ? null : service.allowNotifications,
                  child: const Text(NotificationStrings.allow),
                ),
              ),
            if (service.error != null)
              ListTile(
                subtitle: Text(service.error!),
                trailing: TextButton(
                  onPressed: service.busy ? null : service.refresh,
                  child: const Text(NotificationStrings.retry),
                ),
              ),
          ],
        ),
      );
    },
  );
}
