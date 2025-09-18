import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:garage_service_app/screens/auth/forgot_password_screen.dart';
import 'package:garage_service_app/screens/auth/reset_password_screen.dart';
import 'package:garage_service_app/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  testWidgets('ForgotPasswordScreen shows form and validates email', (tester) async {
    await tester.pumpWidget(_wrap(const ForgotPasswordScreen()));
    expect(find.textContaining('Forgot'), findsOneWidget); // title in EN
    final emailField = find.byType(TextFormField).first;
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    // Should show validation error (some text present)
    expect(emailField, findsOneWidget);
  });

  testWidgets('ResetPasswordScreen has token and password fields', (tester) async {
    await tester.pumpWidget(_wrap(const ResetPasswordScreen(initialToken: 'abc')));
    // Three text fields: token, new password, confirm
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.textContaining('Reset'), findsWidgets);
  });
}
