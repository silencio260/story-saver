import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes_manager.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../bloc/splash_bloc/splash_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
    context.read<AnalyticsBloc>().add(
      const AnalyticsEventLogged(
        AnalyticsEventEntity(name: 'goto_splash_screen'),
      ),
    );
    context.read<SplashBloc>().add(const SplashStarted());
  }

  @override
  Widget build(BuildContext context) => BlocListener<SplashBloc, SplashState>(
    listener: (context, state) async {
      if (_hasNavigated || state.destination == SplashDestination.pending) {
        return;
      }
      _hasNavigated = true;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.read<AnalyticsBloc>().add(
        const AnalyticsEventLogged(
          AnalyticsEventEntity(name: 'goto_home_page'),
        ),
      );
      final route =
          state.destination == SplashDestination.home
              ? Routes.home
              : Routes.onboarding;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    },
    child: const Scaffold(
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          child: Image(
            image: AssetImage('assets/images/app-logo.png'),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),
  );
}
