import 'package:flutter/material.dart';
import 'package:genrevibes_core/genrevibes_core.dart';

import '../../../../bootstrap/app_runtime.dart';

/// Developer-only view of what actually started at launch.
///
/// A degraded module is designed not to crash the app, so without this screen a
/// provider that failed to initialize is invisible on device. Gate it behind
/// the developer section; it names providers and error codes, never secrets.
final class ModuleHealthScreen extends StatelessWidget {
  /// Creates the screen.
  const ModuleHealthScreen({required this.runtime, super.key});

  /// The composed runtime to report on.
  final AppRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final modules = runtime.kit.modules.values.toList()
      ..sort((a, b) => a.moduleId.compareTo(b.moduleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Module health')),
      body: ListView(
        children: <Widget>[
          _Summary(runtime: runtime, started: modules.length),
          const Divider(height: 1),
          for (final module in modules)
            _ModuleTile(health: module.health),
          if (modules.isEmpty)
            const ListTile(
              title: Text('No modules started'),
              subtitle: Text('Initialization did not reach any module.'),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.runtime, required this.started});

  final AppRuntime runtime;
  final int started;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = runtime.initialization.fold(
      onSuccess: (_) => null,
      onFailure: (error) => error,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                runtime.isHealthy ? Icons.check_circle : Icons.error,
                color: runtime.isHealthy
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                runtime.isHealthy
                    ? 'Initialization succeeded'
                    : 'Initialization failed',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$started module${started == 1 ? '' : 's'} started. '
            'Disabled modules are never constructed and do not appear below.',
            style: theme.textTheme.bodySmall,
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '${failure.code.name}: ${failure.message}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.health});

  final ModuleHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color) = switch (health.state) {
      ModuleState.ready => (Icons.check_circle, theme.colorScheme.primary),
      ModuleState.degraded => (Icons.warning_amber, theme.colorScheme.tertiary),
      ModuleState.failed => (Icons.error, theme.colorScheme.error),
      ModuleState.disposed => (Icons.remove_circle_outline, theme.disabledColor),
      _ => (Icons.hourglass_empty, theme.disabledColor),
    };

    final details = health.details.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('  ·  ');

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(health.moduleId),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            health.provider == null
                ? health.state.name
                : '${health.state.name} · ${health.provider}',
          ),
          if (details.isNotEmpty)
            Text(details, style: theme.textTheme.bodySmall),
          if (health.error != null)
            Text(
              '${health.error!.providerCode ?? health.error!.code.name}: '
              '${health.error!.message}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
        ],
      ),
      isThreeLine: details.isNotEmpty || health.error != null,
    );
  }
}
