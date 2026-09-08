import 'package:flutter/material.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_devtools/genrevibes_devtools.dart';

import '../../container_injector.dart';
import '../analytics/domain/entities/app_analytics_catalogue.dart';

/// Opens the analytics bench.
///
/// The bench lives in `genrevibes_devtools` so every application in the
/// portfolio gets the same one; this file is the seam where Story Saver hands
/// it the pieces it owns — the pipeline instance and its own event catalogue.
void openAnalyticsBench(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DevAnalyticsPage(
        pipeline: sl<AnalyticsPipeline>(),
        catalogue: AppAnalyticsCatalogue.catalogue,
      ),
    ),
  );
}
