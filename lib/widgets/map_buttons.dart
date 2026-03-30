import 'package:flutter/material.dart';

class MapFloatingActionButton extends StatelessWidget {
  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  const MapFloatingActionButton({
    super.key,
    required this.heroTag,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: heroTag,
      foregroundColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      tooltip: tooltip,
      onPressed: onPressed,
      child: child,
    );
  }
}

class MapFloatingActionButtonSmall extends StatelessWidget {
  final String heroTag;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  const MapFloatingActionButtonSmall({
    super.key,
    required this.heroTag,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      heroTag: heroTag,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      tooltip: tooltip,
      onPressed: onPressed,
      child: child,
    );
  }
}
