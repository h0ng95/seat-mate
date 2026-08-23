import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'app_router.dart';

class SeatMateApp extends StatelessWidget {
  const SeatMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.serviceName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6652)),
        useMaterial3: true,
      ),
    );
  }
}
