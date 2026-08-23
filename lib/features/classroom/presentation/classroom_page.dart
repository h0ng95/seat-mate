import 'package:flutter/material.dart';

class ClassroomPage extends StatelessWidget {
  const ClassroomPage({required this.shareCode, super.key});

  final String shareCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('교실: $shareCode')));
  }
}
