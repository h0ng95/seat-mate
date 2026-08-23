import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'app_router.dart';
import 'app_theme.dart';

class SeatMateApp extends StatelessWidget {
  const SeatMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.serviceName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
    );
  }
}
