import 'package:flutter/material.dart';

class ScaleOnTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleOnTapWidget({super.key, required this.child, this.onTap});

  @override
  State<ScaleOnTapWidget> createState() => _ScaleOnTapWidgetState();
}

class _ScaleOnTapWidgetState extends State<ScaleOnTapWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
