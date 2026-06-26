import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/moon_logo.dart';
import '../../components/reader_settings_sheet.dart';
import '../../theme/reader_theme.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../viewmodels/app_viewmodel.dart';

/// Settings + About. Bound to [AppViewModel] for the app theme mode and a
/// shortcut into the reading-display sheet.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.screenPadding,
            AppConstants.gapL,
            AppConstants.screenPadding,
            AppConstants.gapXl,
          ),
          children: [
            Text('Settings', style: context.text.headlineSmall),
            const SizedBox(height: AppConstants.gapL),

            _SectionLabel('Appearance'),
            const SizedBox(height: AppConstants.gapS),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {vm.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  context.read<AppViewModel>().setThemeMode(s.first),
            ),

            const SizedBox(height: AppConstants.gapL),
            _SectionLabel('Reading'),
            const SizedBox(height: AppConstants.gapS),
            Card(
              child: ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Reading display'),
                subtitle: Text(
                  '${vm.reader.palette.label} · ${vm.reader.fontSize.round()} pt '
                  '· ${vm.reader.serif ? 'Serif' : 'Sans'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showReaderSettingsSheet(context),
              ),
            ),

            const SizedBox(height: AppConstants.gapL),
            _SectionLabel('About'),
            const SizedBox(height: AppConstants.gapS),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.gapM),
                child: Row(
                  children: [
                    const MoonLogo(size: 60),
                    const SizedBox(width: AppConstants.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppConstants.appName,
                              style: context.text.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            'Version $_version',
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.tagline,
                            style: context.text.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.gapM),
            Text(
              'Typeset in Lora & Inter (bundled, SIL Open Font License). '
              'Starter library uses public-domain texts.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.text.labelMedium?.copyWith(
        color: context.colors.primary,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
