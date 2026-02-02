import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;

  const InfoCard({super.key, required this.title, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white70 : Colors.grey, 
              fontSize: 12
            )
          ),
          const Divider(),
          Expanded(child: child),
        ],
      ),
    );
  }
}