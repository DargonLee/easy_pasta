import 'dart:math';
import 'package:flutter/material.dart';

enum ItemAnimationMode {
  scale,
  fade,
  rotate,
}

class ItemAnimationWidget extends StatefulWidget {
  final Widget child;
  final ItemAnimationMode mode;
  final bool isSelected;
  final double a;

  const ItemAnimationWidget({
    Key? key,
    required this.child,
    required this.isSelected,
    this.mode = ItemAnimationMode.scale,
    this.a = 0.95,
  }) : super(key: key);

  @override
  AnimationWidgetState createState() => new AnimationWidgetState();
}

class AnimationWidgetState extends State<ItemAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      child: widget.child,
      builder: (ctx, child) => _buildByMode(child, widget.mode),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ItemAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  Widget _buildByMode(Widget? child, ItemAnimationMode mode) {
    double rate = (widget.a - 1) * _animationController.value + 1;
    switch (mode) {
      case ItemAnimationMode.scale:
        return Transform.scale(scale: rate, child: widget.child);
      case ItemAnimationMode.fade:
        return Opacity(opacity: rate, child: widget.child);
      case ItemAnimationMode.rotate:
        return Transform.rotate(angle: rate * pi * 2, child: widget.child);
    }
  }
}
