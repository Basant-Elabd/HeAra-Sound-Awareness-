import 'package:flutter/material.dart';

class AnimatedWave extends StatefulWidget {
  final double delay;
  const AnimatedWave({super.key, required this.delay});

  @override
  State<AnimatedWave> createState() => AnimatedWaveState();
}

class AnimatedWaveState extends State<AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double value = (_controller.value + widget.delay) % 1;

        return Opacity(
          opacity: (1 - value),
          child: Transform.scale(
            scale: 1 + value * 1.8,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 71, 92, 128)
                      .withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}