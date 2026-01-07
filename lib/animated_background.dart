import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vora/config/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F7FA), Color(0xFFE4ECF5)],
            ),
          ),
          child: Stack(
            children: [
              _floatingBlob(
                size,
                color: AppColors.sellerAppColor.withOpacity(0.18),
                dx: sin(_controller.value * pi * 2) * 40,
                dy: cos(_controller.value * pi * 2) * 30,
                top: size.height * 0.15,
                left: size.width * 0.1,
              ),
              _floatingBlob(
                size,
                color: AppColors.userAppColor.withOpacity(0.15),
                dx: cos(_controller.value * pi * 2) * 50,
                dy: sin(_controller.value * pi * 2) * 40,
                bottom: size.height * 0.1,
                right: size.width * 0.15,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floatingBlob(
    Size size, {
    required Color color,
    double dx = 0,
    double dy = 0,
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top != null ? top + dy : null,
      left: left != null ? left + dx : null,
      right: right != null ? right + dx : null,
      bottom: bottom != null ? bottom + dy : null,
      child: Container(
        width: size.width * 0.6,
        height: size.width * 0.6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
