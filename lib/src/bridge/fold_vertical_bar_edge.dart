/// The edge where the system places its vertical bar, the strip that iPhone
/// Duo keeps for its controls.
///
/// Reflects where the system wants the bar, whether or not it shows one. On
/// the left of Split View, iOS reports [leading] but gives a Flutter app no
/// inset for the bar.
///
/// Leading and trailing follow the layout direction: in a right-to-left
/// language, iOS calls the right edge leading.
enum FoldVerticalBarEdge {
  /// The system places no vertical bar here, such as on a device without one
  /// or in a size class that does not use it.
  unspecified,

  /// The bar belongs on the leading edge.
  leading,

  /// The bar belongs on the trailing edge.
  trailing,
}
