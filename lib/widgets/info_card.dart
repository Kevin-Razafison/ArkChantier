import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ✅ FIX: Change mainAxisSize to min and remove Expanded widgets
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← CRITICAL FIX
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 15),
          // Don't wrap child in Expanded - let it size itself
          child,
        ],
      ),
    );
  }
}
