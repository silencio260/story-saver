import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_observer.dart';
import 'container_injector.dart';
import 'core/usecase/base_usecase.dart';
import 'features/analytics/domain/usecases/initialize_analytics_usecase.dart';
import 'features/app_services/domain/usecases/initialize_app_services_usecase.dart';
import 'features/settings/presentation/services/legacy/app_rating_service.dart';
import 'features/settings/presentation/services/legacy/feedback_helper.dart';
import 'my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  initAppDependencies();
  await sl<InitializeAnalyticsUseCase>()(NoParams.instance);
  await sl<InitializeAppServicesUseCase>()(NoParams.instance);
  await AdvancedAppRatingService.initialize();
  FeedBackHelper.init();

  runApp(const MyApp());
}
