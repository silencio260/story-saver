import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/routes_manager.dart';
import '../../../../analytics/domain/entities/analytics_event.dart';
import '../../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../../settings/presentation/bloc/settings_bloc/settings_bloc.dart';
import '../../bloc/status_bloc/status_bloc.dart';

/// BLoC-backed compatibility version of the original helper.
void switchToBusinessMode(BuildContext context) {
  final bloc = context.read<StatusBloc>();
  final enabled = !bloc.state.isBusinessMode;
  bloc.add(StatusBusinessModeRequested(enabled: enabled, reloadStatuses: true));
  context.read<AnalyticsBloc>().add(
    AnalyticsEventLogged(
      AnalyticsEventEntity(
        name: enabled ? 'switch_to_business_mode' : 'switch_to_normal_mode',
      ),
    ),
  );
  Navigator.pushNamed(context, Routes.home);
}

bool checkIsBusinessMode(BuildContext context) =>
    context.read<StatusBloc>().state.isBusinessMode;

Future<void> checkAndEnforceBusinessModeAccess(BuildContext context) async {
  final isPremium = context.read<IapBloc>().state.isPremium;
  if (isPremium) return;

  final statusBloc = context.read<StatusBloc>();
  if (statusBloc.state.isBusinessMode) {
    statusBloc.add(
      const StatusBusinessModeRequested(enabled: false, reloadStatuses: true),
    );
    context.read<AnalyticsBloc>().add(
      const AnalyticsEventLogged(
        AnalyticsEventEntity(name: 'switch_to_normal_mode'),
      ),
    );
  }
  final settingsBloc = context.read<SettingsBloc>();
  if (settingsBloc.state.settings.autoSaveEnabled) {
    settingsBloc.add(const AutoSaveChanged(false));
  }
}
