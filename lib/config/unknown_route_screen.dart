import 'package:flutter/material.dart';

import '../core/utils/app_strings.dart';

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text(AppStrings.error)));
}
