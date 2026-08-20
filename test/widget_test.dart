import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with current dashboard', (tester) async {
    // Test mode disables the live market timer/request so this smoke test is
    // deterministic and does not depend on Flutter's blocked test HttpClient.
    await tester.pumpWidget(const IntegratedApp(testMode: true));
    await tester.pump();

    expect(find.byType(IntegratedApp), findsOneWidget);
    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(
      find.text('LIVE MARKET INTELLIGENCE · ENGINE CONNECTED'),
      findsOneWidget,
    );
    expect(find.text('TRADE ENGINE'), findsOneWidget);
    expect(find.text('Waiting for connected market data...'), findsOneWidget);
  });
}
