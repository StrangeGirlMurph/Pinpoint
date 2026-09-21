import 'package:flutter/material.dart';

class ListColorDot extends StatelessWidget {
  final Color? color;
  final double size;
  final bool isRainbow;

  static const List<Color> _rainbowColors = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  const ListColorDot({
    super.key,
    required Color this.color,
    this.size = 16,
  }) : isRainbow = false;

  const ListColorDot.rainbow({
    super.key,
    this.size = 16,
  })  : color = null,
        isRainbow = true;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isRainbow ? null : color,
        gradient: isRainbow
            ? const SweepGradient(
                colors: _rainbowColors,
              )
            : null,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 0.5),
      ),
    );
  }
}
