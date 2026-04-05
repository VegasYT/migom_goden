import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const ProfileAvatar({super.key, this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: cs.primaryContainer,
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _Initials(name: name),
                    ),
                  )
                : _Initials(name: name),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // TODO: image picker
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2.5),
                ),
                child: Icon(Icons.camera_alt_outlined,
                    size: 16, color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    return Text(
      initials,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cs.onPrimaryContainer,
      ),
    );
  }
}
