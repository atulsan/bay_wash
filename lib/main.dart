import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const EmiratesWashApp());

class EmiratesWashApp extends StatefulWidget {
  const EmiratesWashApp({super.key});

  static _EmiratesWashAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_EmiratesWashAppState>()!;

  @override
  State<EmiratesWashApp> createState() => _EmiratesWashAppState();
}

class _EmiratesWashAppState extends State<EmiratesWashApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emirates Wash',
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
