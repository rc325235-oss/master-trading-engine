import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with current dashboard', (tester) async {
    // This is a widget smoke test. The dashboard starts a live HTTP refresh in
    // initState, but Flutter widget tests intentionally do not perform real
    // network requests. Do not assert on feed-dependent widgets here.
    await tester.pumpWidget(const IntegratedApp());
    await tester.pump();

    // These are rendered synchronously by the current dashboard and therefore
    // make the test deterministic in CI.
    expect(find.byType(IntegratedApp), findsOneWidget);
    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(
      find.text('LIVE MARKET INTELLIGENCE · ENGINE CONNECTED'),
      findsOneWidget,
    );
  });
}
