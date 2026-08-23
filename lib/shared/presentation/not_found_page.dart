import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('앗, 교실을 못 찾았어요.'),
            const SizedBox(height: 16),
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
