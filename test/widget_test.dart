import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm/core/theme.dart';
import 'package:crm/core/widgets/common.dart';
import 'package:crm/features/auth/login_screen.dart';

void main() {
  testWidgets('shows the sign-in form', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in to manage your sales workspace.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  test('friendlyError hides raw network exceptions', () {
    final message = friendlyError(
      Exception(
        'ClientException with SocketException: No route to host, '
        'uri=https://example.supabase.co/rest/v1/leads',
      ),
    );

    expect(message, contains('Internet connection unavailable'));
    expect(message, isNot(contains('SocketException')));
    expect(message, isNot(contains('supabase.co')));
  });

  testWidgets('retry view hides raw network exceptions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ErrorRetryView(
            message:
                'Failed to load leads.\nClientException with SocketException: '
                'No route to host, uri=https://example.supabase.co/rest/v1/leads',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Internet connection unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}
