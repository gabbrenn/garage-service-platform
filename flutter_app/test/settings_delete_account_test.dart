import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:garage_service_app/screens/settings/settings_screen.dart';
import 'package:garage_service_app/providers/auth_provider.dart';
import 'package:garage_service_app/providers/theme_provider.dart';
import 'package:garage_service_app/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class TestAuthProvider extends AuthProvider {
  bool loggedOut = false;
  @override
  Future<void> logout(BuildContext? context) async {
    loggedOut = true;
    return; // do not call super to avoid dependencies
  }
}

Widget _buildApp(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuthProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/': (_) => home,
        '/login': (_) => const Scaffold(body: Center(child: Text('Login Screen'))),
      },
    ),
  );
}

void main() {
  testWidgets('Settings delete account flow triggers logout and navigation', (tester) async {
    // Inject a deleteAccount function that returns true
    Future<bool> fakeDelete() async => true;

    await tester.pumpWidget(_buildApp(SettingsScreen(deleteAccount: fakeDelete)));
    await tester.pumpAndSettle();

    // Tap delete button
    final deleteBtn = find.byKey(const Key('deleteAccountButton'));
    expect(deleteBtn, findsOneWidget);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.byType(AlertDialog), findsOneWidget);
    final confirm = find.textContaining('Delete');
    await tester.tap(confirm.last);
    await tester.pumpAndSettle();

    // Expect navigation to login screen
    final loginFinder = find.text('Login Screen');
    expect(loginFinder, findsOneWidget);

    // And provider logout flag flipped (read provider from login screen context)
    final loginElement = tester.element(loginFinder);
    final auth = Provider.of<AuthProvider>(loginElement, listen: false) as TestAuthProvider;
    expect(auth.loggedOut, true);
  });
}
