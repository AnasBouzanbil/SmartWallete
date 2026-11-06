import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Softly pulsing placeholder block shown while data loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppSpacing.radius12,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.circle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(colors.surfaceAlt, colors.outline, _controller.value),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.circle ? null : BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Placeholder that mimics a card of transaction rows.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: colors.outline),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              child: Row(
                children: <Widget>[
                  SkeletonBox(height: 40, circle: true),
                  SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SkeletonBox(width: 140, height: 14),
                        SizedBox(height: AppSpacing.space8),
                        SkeletonBox(width: 90, height: 10),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 64, height: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
