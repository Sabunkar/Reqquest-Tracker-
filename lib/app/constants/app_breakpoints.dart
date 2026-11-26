/// Centralized responsive layout breakpoints and content width constraints
/// for RequestFlow across mobile, tablet, and desktop viewports.
class AppBreakpoints {
  const AppBreakpoints._();

  // --- Viewport Width Breakpoints ---

  /// Screen width threshold for switching from bottom NavigationBar to wide NavigationRail.
  static const double tablet = 720.0;

  /// Compact mobile threshold where horizontal action rows stack vertically to prevent overflow.
  static const double compactMobile = 450.0;

  /// Ultra-narrow mobile width threshold (e.g., small phones, extreme split screen, or 200% font scale).
  static const double narrowMobile = 360.0;

  /// Dashboard metrics grid breakpoint for displaying 3 stat card columns.
  static const double gridMedium = 520.0;

  /// Dashboard metrics grid breakpoint for displaying all 5 stat card columns horizontally.
  static const double gridLarge = 850.0;

  // --- Maximum Content Width Constraints ---

  /// Maximum content width for data-heavy wide screens: Dashboard and Request List.
  static const double maxContentWidthWide = 1040.0;

  /// Maximum content width for information-dense detail views.
  static const double maxContentWidthMedium = 880.0;

  /// Maximum content width for optimal single-column form readability: Create & Edit Request.
  static const double maxContentWidthForm = 760.0;

  /// Maximum content width for settings and preferences lists.
  static const double maxContentWidthCompact = 720.0;
}
