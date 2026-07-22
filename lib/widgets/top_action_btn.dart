import 'package:flutter/material.dart';

class TopActionBtn extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  
  const TopActionBtn({
    super.key,
    this.icon,
    this.child,
    required this.onTap,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Center(
            child: child ?? Icon(
              icon,
              size: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}
