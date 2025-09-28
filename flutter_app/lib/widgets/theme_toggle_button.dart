import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/gen/app_localizations.dart';

/// Reusable icon button that cycles theme mode and exposes localized tooltip.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final themeProv = ctx.watch<ThemeProvider>();
        final loc = AppLocalizations.of(ctx);
        String tooltip;
        switch (themeProv.mode) {
          case ThemeMode.system:
            tooltip = loc.themeSwitchToLight;
            break;
          case ThemeMode.light:
            tooltip = loc.themeSwitchToDark;
            break;
          case ThemeMode.dark:
            tooltip = loc.themeSwitchToSystem;
            break;
        }
        return IconButton(
          key: const Key('themeToggleButton'),
          tooltip: tooltip,
            icon: Icon(
            themeProv.mode == ThemeMode.system
                ? Icons.auto_mode
                : themeProv.mode == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
          ),
          onPressed: () => themeProv.cycleMode(),
        );
      },
    );
  }
}