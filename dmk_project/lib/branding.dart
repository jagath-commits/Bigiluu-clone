import 'package:flutter/material.dart';

/// Safe branding widgets — no asset files required.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    final iconSize = height * 0.45;
    final fontSize = height * 0.28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(height * 0.12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB11226), Color(0xFF8A0C20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(height * 0.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB11226).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(height: height * 0.1),
        Text(
          'Bigilu',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFB11226),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class PoweredByBadge extends StatelessWidget {
  final double height;

  const PoweredByBadge({super.key, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Powered by',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CodeRead',
          style: TextStyle(
            fontSize: height * 0.45,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// Use when image assets are added to pubspec later.
Widget appLogoImage({
  double height = 72,
  String asset = 'assets/images/IMG_9631-removebg-preview.png',
}) {
  return Image.asset(
    asset,
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => AppLogo(height: height),
  );
}
