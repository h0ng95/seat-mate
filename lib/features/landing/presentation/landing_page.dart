import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppConstants.serviceName),
            const Text(AppConstants.serviceTagline),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/create'),
              child: const Text('내 반 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
