import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/app_icon_service.dart';
import 'theme/app_theme.dart';

void main() => runApp(const BayWashApp());

class BayWashApp extends StatefulWidget {
  const BayWashApp({super.key});

  static BayWashAppState of(BuildContext context) =>
      context.findAncestorStateOfType<BayWashAppState>()!;

  @override
  State<BayWashApp> createState() => BayWashAppState();
}

class BayWashAppState extends State<BayWashApp> {
  final _appIconService = const AppIconService();
  Locale _locale = const Locale('en');
  BayWashAppIcon _appIcon = BayWashAppIcon.light;

  Locale get locale => _locale;
  BayWashAppIcon get appIcon => _appIcon;

  void setLocale(Locale locale) => setState(() => _locale = locale);

  Future<bool> setAppIcon(BayWashAppIcon icon) async {
    final changed = await _appIconService.setIcon(icon);
    if (changed && mounted) setState(() => _appIcon = icon);
    return changed;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bay Wash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const SplashScreen(),
    );
  }
}
