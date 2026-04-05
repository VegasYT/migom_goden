import 'package:flutter/material.dart';

class CheckoutSliverHeader extends StatelessWidget {
  final String label;

  const CheckoutSliverHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
