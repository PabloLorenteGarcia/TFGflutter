import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/presentation/providers/settings_provider.dart';

/// Pantalla de configuración de la aplicación
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // Sección de notificaciones
              _buildSectionHeader(context, 'Notificaciones'),
              SwitchListTile(
                title: const Text('Activar notificaciones'),
                subtitle: const Text('Recibe recordatorios de riego'),
                value: settings.notificationsEnabled,
                onChanged: (value) => settings.setNotificationsEnabled(value),
                activeColor: AppColors.primary,
              ),
              ListTile(
                title: const Text('Recordatorio de riego'),
                subtitle: Text('Cada ${settings.defaultWateringReminderHours} horas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showReminderDialog(context, settings),
              ),
              const Divider(),

              // Sección de apariencia
              _buildSectionHeader(context, 'Apariencia'),
              SwitchListTile(
                title: const Text('Modo oscuro'),
                subtitle: const Text('Cambia el tema de la app'),
                value: settings.darkMode,
                onChanged: (value) => settings.setDarkMode(value),
                activeColor: AppColors.primary,
              ),
              const Divider(),

              // Sección de información
              _buildSectionHeader(context, 'Información'),
              ListTile(
                title: const Text('Acerca de PlantCare'),
                subtitle: const Text('Versión 1.0.0'),
                trailing: const Icon(Icons.info_outline),
                onTap: () => _showAboutDialog(context),
              ),
              ListTile(
                title: const Text('Ayuda'),
                subtitle: const Text('Preguntas frecuentes'),
                trailing: const Icon(Icons.help_outline),
                onTap: () => _showHelpDialog(context),
              ),
              const SizedBox(height: 24),

              // Créditos
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '🌱 PlantCare - Cuidando tus plantas con amor',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReminderDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frecuencia de recordatorio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReminderOption(context, settings, 12, '12 horas'),
            _buildReminderOption(context, settings, 24, '24 horas'),
            _buildReminderOption(context, settings, 48, '2 días'),
            _buildReminderOption(context, settings, 72, '3 días'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOption(
    BuildContext context,
    SettingsProvider settings,
    int hours,
    String label,
  ) {
    return RadioListTile<int>(
      title: Text(label),
      value: hours,
      groupValue: settings.defaultWateringReminderHours,
      onChanged: (value) {
        if (value != null) {
          settings.setDefaultWateringReminder(value);
          Navigator.pop(context);
        }
      },
      activeColor: AppColors.primary,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_florist, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('PlantCare'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0'),
            SizedBox(height: 16),
            Text(
              'PlantCare es una aplicación para gestionar el cuidado de tus plantas. '
              'Registra tus plantas, recibe recordatorios de riego y descubre nuevas especies.',
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 PlantCare',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 Preguntas Frecuentes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '¿Cómo añado una planta?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Ve a "Mis Plantas" y pulsa el botón + para añadir una nueva planta.',
              ),
              SizedBox(height: 12),
              Text(
                '¿Cómo funciona el quiz?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Responde las preguntas sobre las condiciones de tu planta y te mostraremos posibles coincidencias.',
              ),
              SizedBox(height: 12),
              Text(
                '¿Puedo editar una planta?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Sí, entra en los detalles de una planta y pulsa el botón de editar.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}