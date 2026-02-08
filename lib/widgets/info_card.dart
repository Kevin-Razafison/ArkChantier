import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool constrainHeight;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.constrainHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (constrainHeight) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 180),
        child: child,
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16), // Réduit de 20 à 16
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12), // Réduit de 15 à 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, // Réduit de 10 à 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}
