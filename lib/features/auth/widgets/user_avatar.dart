import 'package:flutter/material.dart';

import 'package:homie/features/auth/models/user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.user,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final User user;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl?.trim();
    final fallback = Center(
      child: Text(
        _initials(user.fullName),
        style: TextStyle(
          color: foregroundColor ?? Theme.of(context).colorScheme.primary,
          fontSize: radius * .58,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      child: ClipOval(
        child: avatarUrl == null || avatarUrl.isEmpty
            ? SizedBox.square(dimension: radius * 2, child: fallback)
            : Image.network(
                avatarUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    SizedBox.square(dimension: radius * 2, child: fallback),
              ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }
}
