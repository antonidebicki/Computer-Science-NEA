import 'package:flutter/cupertino.dart';

/// Provider for managing app theme brightness (light/dark mode)
class ThemeProvider extends ChangeNotifier {
  Brightness _brightness = Brightness.light;

  Brightness get brightness => _brightness;

  bool get isDark => _brightness == Brightness.dark;

  void toggleBrightness() {
    _brightness = _brightness == Brightness.light 
        ? Brightness.dark 
        : Brightness.light;
    notifyListeners();
  }

  void setBrightness(Brightness brightness) {
    if (_brightness != brightness) {
      _brightness = brightness;
      notifyListeners();
    }
  }

  void setLight() => setBrightness(Brightness.light);
  
  void setDark() => setBrightness(Brightness.dark);
}
