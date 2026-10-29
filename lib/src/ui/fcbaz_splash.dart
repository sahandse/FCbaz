import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class FcbazSplash extends StatelessWidget {
  const FcbazSplash({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = FcbazPalette.dark;
    return Scaffold(
      backgroundColor: palette.canvas,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.35),
            radius: 1.1,
            colors: [
              palette.primary.withValues(alpha: .12),
              palette.canvas.withValues(alpha: 0),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: .28),
                      blurRadius: 34,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Text(
                  'FC',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: palette.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FCBaz',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: 'BarlowCondensed',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'همراه فارسی FC 27',
                style: TextStyle(color: palette.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 104,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: palette.surfaceRaised,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
