import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_spacing.dart';

class ChalkLoading extends StatefulWidget {
  const ChalkLoading({
    this.messages = const ['칠판 닦는 중...', '책상 옮기는 중...'],
    super.key,
  });

  final List<String> messages;

  @override
  State<ChalkLoading> createState() => _ChalkLoadingState();
}

class _ChalkLoadingState extends State<ChalkLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 88,
          height: 10,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Align(
              alignment: disableAnimations
                  ? Alignment.center
                  : Alignment(_controller.value * 2 - 1, 0),
              child: child,
            ),
            child: Container(
              width: 30,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.chalk,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.line),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(widget.messages.first),
      ],
    );
  }
}
