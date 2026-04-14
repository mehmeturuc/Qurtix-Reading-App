class ResponsiveGrid {
  const ResponsiveGrid._();

  static int columnsForWidth(double width) {
    if (width >= 1100) return 5;
    if (width >= 840) return 4;
    if (width >= 560) return 3;
    return 2;
  }
}
