import 'package:flutter/material.dart';

/// Flat list (3D tilt removed — classic WhatsApp).
class PerspectiveScrollList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder!,
        itemBuilder: itemBuilder,
      );
    }
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
