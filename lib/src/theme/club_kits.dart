import 'package:flutter/material.dart';

@immutable
class ClubKit {
  const ClubKit({
    required this.label,
    required this.accent,
    required this.tagline,
  });

  final String label;
  final Color accent;
  final String tagline;
}

const kClubKits = <ClubKit>[
  ClubKit(label: 'سبز EA', accent: Color(0xFFC8FF42), tagline: 'امضای FCBaz'),
  ClubKit(
    label: 'فیروزه‌ای سیتی',
    accent: Color(0xFF7DEBFF),
    tagline: 'مدرن و خنک',
  ),
  ClubKit(
    label: 'طلایی آیکان',
    accent: Color(0xFFFFD700),
    tagline: 'برای کارت‌های ویژه',
  ),
  ClubKit(
    label: 'قرمز شیاطین',
    accent: Color(0xFFFF3366),
    tagline: 'پرهیجان و تهاجمی',
  ),
  ClubKit(
    label: 'بنفش هولوگرافیک',
    accent: Color(0xFFB388FF),
    tagline: 'درخشان و متفاوت',
  ),
  ClubKit(
    label: 'آبی سلطنتی',
    accent: Color(0xFF82B1FF),
    tagline: 'آرام و کلاسیک',
  ),
];

ClubKit? clubKitFor(int accentColorValue) {
  for (final kit in kClubKits) {
    if (kit.accent.toARGB32() == accentColorValue) return kit;
  }
  return null;
}
