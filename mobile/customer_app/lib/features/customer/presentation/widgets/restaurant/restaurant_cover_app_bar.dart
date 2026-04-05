import 'package:flutter/material.dart';

class RestaurantCoverImage extends StatelessWidget {
  final String url;
  const RestaurantCoverImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RestaurantCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RestaurantCircleIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
