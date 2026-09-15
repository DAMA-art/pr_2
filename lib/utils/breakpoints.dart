class Breakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double contentMax = 1400;

  static bool isPhone(double width) => width < phone;
  static bool isTablet(double width) => width >= phone && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}
