/// Design tokens for dokki.
///
/// The visual language: a *vault* should feel calm, precise and
/// trustworthy — ink on paper, not neon on glass. Deep ink-navy primary,
/// warm off-white "paper" surfaces in light mode, soft charcoal in dark,
/// and a single restrained brass accent reserved for security affordances
/// (locks, keys, the recovery passphrase) so it always means "this is
/// about your keys".
library;

import 'package:flutter/material.dart';
import 'package:vault_domain/vault_domain.dart';

abstract final class DokkiColors {
  /// Seed for the Material 3 scheme: deep ink navy.
  static const ink = Color(0xFF1B2A4A);

  /// Reserved for security affordances only.
  static const brass = Color(0xFFB8862B);

  /// Light "paper" ground.
  static const paper = Color(0xFFFAF8F4);
  static const paperLow = Color(0xFFF3F0EA);
  static const paperHigh = Color(0xFFFFFFFF);

  /// Dark "slate" ground.
  static const slate = Color(0xFF121417);
  static const slateLow = Color(0xFF1A1D22);
  static const slateHigh = Color(0xFF23272E);
}

abstract final class DokkiSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class DokkiRadius {
  static const double chip = 10;
  static const double card = 16;
  static const double sheet = 28;
  static const double tile = 14;
}

abstract final class DokkiDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 400);
}

/// Each entry type carries a fixed icon and hue so a grid is scannable at
/// a glance. Hues are muted so thumbnails, not chrome, own the colour.
final class EntryTypeStyle {
  const EntryTypeStyle({
    required this.label,
    required this.pluralLabel,
    required this.icon,
    required this.hue,
    required this.hint,
  });

  final String label;
  final String pluralLabel;
  final IconData icon;

  /// A brand-neutral hue; tinted onto the current scheme at low alpha.
  final Color hue;

  /// One line of copy for the "add" sheet.
  final String hint;

  static EntryTypeStyle of(EntryType type) => switch (type) {
    EntryType.photo => const EntryTypeStyle(
      label: 'Photo',
      pluralLabel: 'Photos',
      icon: Icons.photo_outlined,
      hue: Color(0xFF3B6EA5),
      hint: 'A passport photo, a headshot, anything single-image.',
    ),
    EntryType.id => const EntryTypeStyle(
      label: 'ID',
      pluralLabel: 'IDs',
      icon: Icons.badge_outlined,
      hue: Color(0xFF6D4FA3),
      hint: 'Front and back of a card, edited together.',
    ),
    EntryType.signature => const EntryTypeStyle(
      label: 'Signature',
      pluralLabel: 'Signatures',
      icon: Icons.draw_outlined,
      hue: Color(0xFF2B8A7E),
      hint: 'Your signature on white, ready to place on forms.',
    ),
    EntryType.thumbprint => const EntryTypeStyle(
      label: 'Thumbprint',
      pluralLabel: 'Thumbprints',
      icon: Icons.fingerprint,
      hue: Color(0xFFB8862B),
      hint: 'A scanned thumbprint impression.',
    ),
    EntryType.document => const EntryTypeStyle(
      label: 'Document',
      pluralLabel: 'Documents',
      icon: Icons.description_outlined,
      hue: Color(0xFF4E8A3E),
      hint: 'Multi-page: add pages, reorder, export as one PDF later.',
    ),
  };

  /// Tint for badges and empty tiles: the hue blended into the surface.
  Color tintOn(ColorScheme scheme) =>
      Color.alphaBlend(hue.withValues(alpha: 0.14), scheme.surfaceContainer);

  Color foregroundOn(ColorScheme scheme) => scheme.brightness == Brightness.dark
      ? Color.lerp(hue, Colors.white, 0.35)!
      : Color.lerp(hue, Colors.black, 0.15)!;
}
