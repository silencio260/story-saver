import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/folder_screenshot_guide.dart';

import '../../../../config/routes_manager.dart';
import '../../../monetization/presentation/controllers/legacy/ad_suppression_manager.dart';
import '../../../statuses/presentation/bloc/status_bloc/status_bloc.dart';
import '../../data/services/status_connection_journey.dart';
import '../bloc/permissions_bloc/permissions_bloc.dart';
import '../l10n/permission_strings.dart';

class StatusFolderPermissionScreen extends StatefulWidget {
  const StatusFolderPermissionScreen({required this.isBusinessMode, super.key});
  final bool isBusinessMode;
  @override
  State<StatusFolderPermissionScreen> createState() =>
      _StatusFolderPermissionScreenState();
}

class _StatusFolderPermissionScreenState
    extends State<StatusFolderPermissionScreen> {
  bool _requestInProgress = false;
  bool _attempted = false;
  String? _message;
  late final String _suppression =
      'folder_connection_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    AdSuppressionManager().suppressAds(_suppression);
    StatusConnectionJourney.instance.begin(business: widget.isBusinessMode);
  }

  @override
  void dispose() {
    AdSuppressionManager().enableAds(_suppression);
    super.dispose();
  }

  void _requestPermission() {
    if (_requestInProgress) return;
    setState(() {
      _requestInProgress = true;
      _attempted = true;
      _message = null;
    });
    StatusConnectionJourney.instance.record('status_connection_picker_opened');
    context.read<PermissionsBloc>().add(
      StatusFolderPermissionRequested(isBusinessMode: widget.isBusinessMode),
    );
  }

  void _leave({bool connected = false}) {
    if (connected) context.read<StatusBloc>().add(const StatusLoadRequested());
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<PermissionsBloc, PermissionsState>(
    listenWhen:
        (before, after) =>
            _requestInProgress &&
            (after.status == PermissionViewStatus.ready ||
                after.status == PermissionViewStatus.failure),
    listener: (context, state) {
      final granted =
          state.status == PermissionViewStatus.ready &&
          state.hasStatusFolderPermission(
            isBusinessMode: widget.isBusinessMode,
          );
      setState(() {
        _requestInProgress = false;
        final otherGranted = state.hasStatusFolderPermission(
          isBusinessMode: !widget.isBusinessMode,
        );
        _message =
            state.errorMessage ??
            (otherGranted
                ? '${widget.isBusinessMode ? 'WhatsApp' : 'WhatsApp Business'} is connected. For both apps, choose Android → media.'
                : PermissionStrings.denied);
      });
      StatusConnectionJourney.instance.record(
        granted
            ? 'status_connection_granted'
            : state.status == PermissionViewStatus.failure
            ? 'status_connection_failed'
            : 'status_connection_cancelled',
      );
      if (granted) {
        _leave(connected: true);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_message!),
              duration: const Duration(seconds: 6),
            ),
          );
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Connect status folders')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null)
                Semantics(
                  liveRegion: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _requestInProgress ? null : _requestPermission,
                child: Text(
                  _requestInProgress
                      ? 'Finding statuses…'
                      : _attempted
                      ? 'Try again'
                      : 'Choose media folder',
                ),
              ),
              TextButton(
                onPressed:
                    _requestInProgress
                        ? null
                        : () {
                          StatusConnectionJourney.instance.record(
                            'status_connection_skipped',
                          );
                          _leave();
                        },
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connect your statuses',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a folder. We’ll find the statuses.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const FolderScreenshotGuide(),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  ExpansionTile(
                    title: const Text('Android won’t let me use media'),
                    subtitle: const Text('Try a WhatsApp folder'),
                    onExpansionChanged: (open) {
                      if (open)
                        StatusConnectionJourney.instance.record(
                          'status_connection_help_opened',
                        );
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: FolderScreenshotGuide(
                          detailed: true,
                          business: widget.isBusinessMode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
