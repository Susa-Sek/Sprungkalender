import 'package:material_ui/material_ui.dart';

/// Ein gemeinsames Raster für die ganze App.
///
/// Übernommen aus „Täglich Klüger" — demselben Autor, dieselbe Handschrift.
/// Diese Konstanten geben einen Takt vor, an dem sich alles ausrichtet,
/// statt Abstände pro Bildschirm zu raten.
abstract final class Insets {
  /// Vier-Punkt-Raster: alle Abstände sind Vielfache davon.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Seitenrand für Inhalte.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Innenabstand einer Karte.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class Radii {
  static const double card = 16;
  static const double chip = 12;
  static const double bar = 4;

  static const BorderRadius cardShape = BorderRadius.all(Radius.circular(card));
  static const BorderRadius chipShape = BorderRadius.all(Radius.circular(chip));
}

/// Kleinste Tippfläche nach den Android- und iOS-Richtlinien.
const double kMinTapTarget = 48;

/// Dauer für die kurzen Übergänge.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Das Erscheinungsbild der App.
///
/// Ruhig und warm: ein gedecktes Blauviolett als Grundton, ein cremiger
/// Hintergrund im Hellen, abgerundete Flächen statt harter Linien.
ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5A67C8),
    brightness: brightness,
  );
  final bool light = brightness == Brightness.light;
  final Color hintergrund = light ? const Color(0xFFF8F6F2) : scheme.surface;
  final Color flaeche = light ? Colors.white : scheme.surfaceContainerHigh;

  final TextTheme basis =
      (light
              ? Typography.material2021().black
              : Typography.material2021().white)
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final TextTheme text = basis.copyWith(
    headlineSmall: basis.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: basis.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: basis.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: basis.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  // Wichtig: Size(64, 48) und NICHT Size.fromHeight(48). Letzteres heißt
  // „unendlich breit" — in einer Row lässt sich so ein Knopf nicht anordnen,
  // und in der Release-App fehlte er dann einfach. Genau so war der
  // „Übernehmen"-Knopf im Termin-Blatt verschwunden. Wo ein Knopf die volle
  // Breite haben soll, sagt die Stelle das selbst.
  const Size knopf = Size(64, kMinTapTarget);
  const OutlinedBorder knopfForm = RoundedRectangleBorder(
    borderRadius: Radii.chipShape,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    textTheme: text,
    scaffoldBackgroundColor: hintergrund,
    // Karten überall gleich: ruhige Kante statt Schattenstapel.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: flaeche,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.cardShape,
        side: BorderSide(
          color: light ? const Color(0x0F000000) : const Color(0x1FFFFFFF),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: hintergrund,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
      titleTextStyle: text.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: knopf,
        shape: knopfForm,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: knopf,
        shape: knopfForm,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: knopf, shape: knopfForm),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(0, kMinTapTarget),
        selectedBackgroundColor: scheme.secondaryContainer,
        selectedForegroundColor: scheme.onSecondaryContainer,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      selectedColor: scheme.secondaryContainer,
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: Insets.xs),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerHighest,
      border: const OutlineInputBorder(
        borderRadius: Radii.chipShape,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.chipShape,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: flaeche,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: flaeche,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: flaeche,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: scheme.primaryContainer,
      headerForegroundColor: scheme.onPrimaryContainer,
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: Insets.md),
    dividerTheme: DividerThemeData(
      space: 1,
      thickness: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.primaryContainer,
      linearMinHeight: 8,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.bar)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: flaeche,
      indicatorColor: scheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
