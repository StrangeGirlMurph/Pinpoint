import 'dart:async';
import 'package:flutter/material.dart';

enum SnackBarPosition {
  bottom,
  top,
}

OverlayEntry? _activeTopSnackBarEntry;

void hideCurrentSnackBar(BuildContext context) {
  try {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  } catch (_) {}
  _dismissActiveTopSnackBar();
}

void _dismissActiveTopSnackBar() {
  if (_activeTopSnackBarEntry?.mounted ?? false) {
    _activeTopSnackBarEntry?.remove();
  }
  _activeTopSnackBarEntry = null;
}

void showSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
  bool persist = false,
  SnackBarPosition position = SnackBarPosition.bottom,
}) {
  if (position == SnackBarPosition.top) {
    _showTopSnackBar(
      context,
      message,
      action: action,
      duration: duration,
      persist: persist,
    );
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  _dismissActiveTopSnackBar();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      persist: persist,
    ),
  );
}

void _showTopSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  required Duration duration,
  required bool persist,
}) {
  _dismissActiveTopSnackBar();
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  // Insert into the root overlay so the snackbar renders above modal routes
  // (such as modal bottom sheets and dialogs).
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _TopSnackBarWidget(
      message: message,
      action: action,
      duration: duration,
      persist: persist,
      onDismissed: () {
        if (_activeTopSnackBarEntry == entry) {
          _activeTopSnackBarEntry = null;
        }
        if (entry.mounted) {
          entry.remove();
        }
      },
    ),
  );

  _activeTopSnackBarEntry = entry;
  overlay.insert(entry);
}

class _TopSnackBarWidget extends StatefulWidget {
  final String message;
  final SnackBarAction? action;
  final Duration duration;
  final bool persist;
  final VoidCallback onDismissed;

  const _TopSnackBarWidget({
    required this.message,
    this.action,
    required this.duration,
    required this.persist,
    required this.onDismissed,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  final Key _dismissibleKey = UniqueKey();
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    if (!widget.persist) {
      _dismissTimer = Timer(widget.duration, _dismiss);
    }
  }

  void _dismiss() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final snackTheme = Theme.of(context).snackBarTheme;
    final backgroundColor = snackTheme.backgroundColor ??
        Theme.of(context).colorScheme.inverseSurface;

    final action = widget.action == null
        ? null
        : SnackBarAction(
            key: widget.action!.key,
            label: widget.action!.label,
            textColor: widget.action!.textColor,
            disabledTextColor: widget.action!.disabledTextColor,
            backgroundColor: widget.action!.backgroundColor,
            disabledBackgroundColor: widget.action!.disabledBackgroundColor,
            onPressed: () {
              widget.action!.onPressed();
              _dismiss();
            },
          );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: _dismissibleKey,
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismissed(),
            child: Material(
              elevation: snackTheme.elevation ?? 6.0,
              color: backgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Extends the solid background color seamlessly behind the status bar
                  SizedBox(height: topSafeArea),
                  MediaQuery.removePadding(
                    context: context,
                    // SnackBar by default adds bottom safe-area padding; remove it here
                    // so the snackbar retains standard 48px height at the top of screen.
                    removeBottom: true,
                    child: SnackBar(
                      // Outer SlideTransition handles entrance; disable inner animation.
                      animation: kAlwaysCompleteAnimation,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      // Disable inner swipe-down to let outer Dismissible handle swipe-up without conflict.
                      dismissDirection: DismissDirection.none,
                      content: Text(widget.message),
                      action: action,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
