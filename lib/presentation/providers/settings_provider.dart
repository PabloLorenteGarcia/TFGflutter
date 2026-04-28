import 'package:flutter/foundation.dart';

/// Provider para gestionar la configuración de la aplicación
class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  int _defaultWateringReminderHours = 24;
  bool _darkMode = false;

  bool get notificationsEnabled => _notificationsEnabled;
  int get defaultWateringReminderHours => _defaultWateringReminderHours;
  bool get darkMode => _darkMode;

  /// Activa o desactiva las notificaciones
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  /// Configura las horas por defecto para recordatorios de riego
  void setDefaultWateringReminder(int hours) {
    _defaultWateringReminderHours = hours;
    notifyListeners();
  }

  /// Activa o desactiva el modo oscuro
  void setDarkMode(bool enabled) {
    _darkMode = enabled;
    notifyListeners();
  }
}