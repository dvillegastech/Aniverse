import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/appearance/providers/theme_mode_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'flex_scheme_color_state_provider.g.dart';

@riverpod
class FlexSchemeColorState extends _$FlexSchemeColorState {
  @override
  FlexSchemeColor build() {
    final flexSchemeColorIndex = isar.settings
        .getSync(227)!
        .flexSchemeColorIndex!;
    return ref.read(themeModeStateProvider)
        ? ThemeAA.schemes[flexSchemeColorIndex].dark
        : ThemeAA.schemes[flexSchemeColorIndex].light;
  }

  void setTheme(FlexSchemeColor color, int index) {
    final settings = isar.settings.getSync(227);
    state = color;
    isar.writeTxnSync(
      () => isar.settings.putSync(settings!..flexSchemeColorIndex = index),
    );
  }
}

class ThemeAA {
  static const List<FlexSchemeData> schemes = <FlexSchemeData>[
    // Custom Theme 1: Obsidian Inferno (Imposing Orange & Black)
    FlexSchemeData(
      name: 'Obsidian Inferno',
      description: 'Volcanic obsidian with molten lava orange',
      light: FlexSchemeColor(
        primary: Color(0xFFFF4500),         // Naranja rojo ardiente (OrangeRed)
        primaryContainer: Color(0xFFFF6000), // Naranja lava
        secondary: Color(0xFF000000),       // Negro absoluto
        secondaryContainer: Color(0xFF1A1A1A), // Negro carbón
        tertiary: Color(0xFFFF8C00),        // Naranja oscuro (DarkOrange)
        tertiaryContainer: Color(0xFFFFA500), // Naranja puro
        appBarColor: Color(0xFFFF4500),     // Naranja rojo ardiente
        error: Color(0xFF8B0000),           // Rojo oscuro
        errorContainer: Color(0xFFDC143C),   // Carmesí
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFFF5500),         // Naranja volcánico brillante
        primaryContainer: Color(0xFFFF4500), // OrangeRed
        secondary: Color(0xFF000000),       // Negro absoluto
        secondaryContainer: Color(0xFF0D0D0D), // Negro profundo
        tertiary: Color(0xFFFF7F00),        // Naranja coral
        tertiaryContainer: Color(0xFFFF6347), // Naranja tomate
        appBarColor: Color(0xFF1A1A1A),     // Negro carbón
        error: Color(0xFFFF0000),           // Rojo puro
        errorContainer: Color(0xFFCC0000),   // Rojo oscuro
      ),
    ),
    
    // Custom Theme 2: Crimson Force (Strong Red)
    FlexSchemeData(
      name: 'Crimson Force',
      description: 'Powerful pure red with intense dominance',
      light: FlexSchemeColor(
        primary: Color(0xFFCC0000),         // Rojo puro fuerte
        primaryContainer: Color(0xFF990000), // Rojo oscuro intenso
        secondary: Color(0xFFFF6B35),       // Naranja vibrante
        secondaryContainer: Color(0xFFFF4500), // Naranja rojo
        tertiary: Color(0xFF000000),        // Negro absoluto
        tertiaryContainer: Color(0xFF1A1A1A), // Negro carbón
        appBarColor: Color(0xFF990000),     // Rojo oscuro intenso
        error: Color(0xFF4A0000),           // Rojo muy oscuro
        errorContainer: Color(0xFF7F0000),   // Rojo oscuro
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFFF0000),         // Rojo puro brillante
        primaryContainer: Color(0xFFCC0000), // Rojo fuerte
        secondary: Color(0xFFFF8C00),       // Naranja oscuro
        secondaryContainer: Color(0xFFFF6B35), // Naranja vibrante
        tertiary: Color(0xFF000000),        // Negro absoluto
        tertiaryContainer: Color(0xFF0D0D0D), // Negro profundo
        appBarColor: Color(0xFF660000),     // Rojo muy oscuro
        error: Color(0xFFFF4500),           // Naranja rojo
        errorContainer: Color(0xFFDC143C),   // Carmesí
      ),
    ),
    
    // Custom Theme 3: Blood Warrior (Intense Dark Red)
    FlexSchemeData(
      name: 'Blood Warrior',
      description: 'Dark blood red with fierce intensity',
      light: FlexSchemeColor(
        primary: Color(0xFF8B0000),         // Rojo sangre oscuro
        primaryContainer: Color(0xFF660000), // Rojo muy oscuro
        secondary: Color(0xFFFF7043),       // Naranja coral
        secondaryContainer: Color(0xFFFF5722), // Naranja profundo
        tertiary: Color(0xFF212121),        // Negro gris
        tertiaryContainer: Color(0xFF303030), // Gris muy oscuro
        appBarColor: Color(0xFF660000),     // Rojo muy oscuro
        error: Color(0xFF1A0000),           // Rojo casi negro
        errorContainer: Color(0xFF330000),   // Rojo oscurísimo
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFFDC143C),         // Carmesí brillante
        primaryContainer: Color(0xFFB71C1C), // Rojo profundo
        secondary: Color(0xFFFF9800),       // Naranja estándar
        secondaryContainer: Color(0xFFFF7043), // Naranja coral
        tertiary: Color(0xFF0A0A0A),        // Negro casi puro
        tertiaryContainer: Color(0xFF1A1A1A), // Negro carbón
        appBarColor: Color(0xFF4A0000),     // Rojo muy oscuro
        error: Color(0xFFFF5722),           // Naranja profundo
        errorContainer: Color(0xFFE64A19),   // Naranja oscuro
      ),
    ),
    
    // Custom Theme 4: Emerald Dynasty (Green & Teal)
    FlexSchemeData(
      name: 'Emerald Dynasty',
      description: 'Luxurious emerald with jade accents',
      light: FlexSchemeColor(
        primary: Color(0xFF00695C),
        primaryContainer: Color(0xFF00796B),
        secondary: Color(0xFF00BFA5),
        secondaryContainer: Color(0xFF1DE9B6),
        tertiary: Color(0xFF004D40),
        tertiaryContainer: Color(0xFF00695C),
        appBarColor: Color(0xFF00695C),
        error: Color(0xFFD32F2F),
        errorContainer: Color(0xFFEF5350),
      ),
      dark: FlexSchemeColor(
        primary: Color(0xFF4DB6AC),
        primaryContainer: Color(0xFF26A69A),
        secondary: Color(0xFF64FFDA),
        secondaryContainer: Color(0xFF1DE9B6),
        tertiary: Color(0xFF00796B),
        tertiaryContainer: Color(0xFF00897B),
        appBarColor: Color(0xFF001F1A),
        error: Color(0xFFEF5350),
        errorContainer: Color(0xFFE53935),
      ),
    ),
    
    // Include original themes after custom ones
    ...FlexColor.schemesList,
  ];
}
