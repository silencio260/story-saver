import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../../../config/routes_manager.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
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
  BuildContext? _overlayContext;

  Future<void> _requestPermission(BuildContext overlayContext) async {
    setState(() => _requestInProgress = true);
    _overlayContext = overlayContext;
    overlayContext.loaderOverlay.show();
    _log('request_whatsapp_folder_permission');
    context.read<PermissionsBloc>().add(
      StatusFolderPermissionRequested(isBusinessMode: widget.isBusinessMode),
    );
  }

  void _log(String name) {
    context.read<AnalyticsBloc>().add(
      AnalyticsEventLogged(AnalyticsEventEntity(name: name)),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<PermissionsBloc, PermissionsState>(
    listenWhen:
        (previous, current) =>
            _requestInProgress && previous.status != current.status,
    listener: (context, state) {
      if (state.status == PermissionViewStatus.requesting) return;
      _overlayContext?.loaderOverlay.hide();
      _requestInProgress = false;
      final granted = state.hasStatusFolderPermission(
        isBusinessMode: widget.isBusinessMode,
      );
      if (state.status == PermissionViewStatus.ready && granted) {
        _log(
          widget.isBusinessMode
              ? 'grant_business_folder_permission'
              : 'grant_whatsapp_folder_permission',
        );
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
      } else {
        // A refusal and a broken picker are different problems and were two
        // events before the migration: one is the user saying no, the other is
        // the flow failing to ask. Collapsing them hid every SAF failure
        // inside the denial rate.
        if (state.status == PermissionViewStatus.failure) {
          _log('app_error_operation_failed');
        }
        _log(
          widget.isBusinessMode
              ? 'denied_business_folder_permission'
              : 'denied_whatsapp_folder_permission',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? PermissionStrings.denied),
          ),
        );
      }
    },
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00574B),
        title: const Text(
          PermissionStrings.screenTitle,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: LoaderOverlay(
        overlayWidgetBuilder:
            (_) => const Center(
              child: SpinKitCubeGrid(color: Color(0xFF00574B), size: 50),
            ),
        child: Builder(
          builder:
              (overlayContext) => ColoredBox(
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 40),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        PermissionStrings.explanation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          PermissionStrings.steps,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStep(
                      widget.isBusinessMode
                          ? PermissionStrings.businessStepOne
                          : PermissionStrings.regularStepOne,
                    ),
                    _buildStep(PermissionStrings.stepTwo),
                    _buildStep(PermissionStrings.stepThree),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _requestPermission(overlayContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00574B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            PermissionStrings.allowPermission,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    ),
  );

  Widget _buildStep(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(left: 30, right: 20, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}
