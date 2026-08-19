import 'package:flutter/material.dart';

class SlideIndicator extends StatefulWidget {
  final bool active;
  final Function() onCompleted;
  final int pageIndex, index;
  const SlideIndicator(
      {super.key,
      required this.pageIndex,
      required this.index,
      required this.onCompleted,
      required this.active});

  @override
  State<SlideIndicator> createState() => _SlideIndicatorState();
}

class _SlideIndicatorState extends State<SlideIndicator>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: const Duration(seconds: 6), vsync: this);
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted();
      });
    if (widget.active) controller.forward();
  }

  @override
  void didUpdateWidget(SlideIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        controller.forward(from: 0);
      } else {
        controller.reset();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
                height: 3,
                child: Stack(children: [
                  Container(width: double.infinity, color: Colors.white60),
                  SizedBox(
                      width: constraints.biggest.width *
                          (widget.pageIndex < widget.index
                              ? 1
                              : animation.value),
                      child: Container(color: Colors.white))
                ]));
          });
        });
  }
}
