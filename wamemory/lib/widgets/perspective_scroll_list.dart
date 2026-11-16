import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scroll-linked 3D tilt for list rows (glass cards rise in perspective).
class PerspectiveScrollList extends StatefulWidget {
  const PerspectiveScrollList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  State<PerspectiveScrollList> createState() => _PerspectiveScrollListState();
}

class _PerspectiveScrollListState extends State<PerspectiveScrollList> {
  final _controller = ScrollController();
  double _scroll = 0;

  ScrollController get _c => widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onScroll);
  }

  @override
  void dispose() {
    _c.removeListener(_onScroll);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scroll = _c.offset);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final hasSep = widget.separatorBuilder != null;
    final count = hasSep ? math.max(0, widget.itemCount * 2 - 1) : widget.itemCount;

    return ListView.builder(
      controller: _c,
      padding: widget.padding,
      itemCount: count,
      itemBuilder: (context, index) {
        if (hasSep && index.isOdd) {
          return widget.separatorBuilder!(context, index ~/ 2);
        }
        final i = hasSep ? index ~/ 2 : index;
        final child = widget.itemBuilder(context, i);
        if (reduce) return child;

        // Approximate row center vs viewport for tilt.
        const rowH = 78.0;
        final viewH = MediaQuery.sizeOf(context).height;
        final itemY = i * rowH - _scroll + 120;
        final mid = viewH * 0.42;
        final delta = ((itemY - mid) / viewH).clamp(-1.0, 1.0);
        final tilt = delta * 0.14; // ~8°
        final scale = 1 - (delta.abs() * 0.04);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0016)
            ..rotateX(tilt)
            ..scaleByDouble(scale, scale, scale, 1),
          child: child,
        );
      },
    );
  }
}
