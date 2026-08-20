import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with current dashboard', (tester) async {
    await tester.pumpWidget(const IntegratedApp());
    await tester.pump(const Duration(milliseconds: 100));

    // The current dashboard is identified by its stable header. The sidebar
    // is responsive and may intentionally be hidden on narrow test surfaces,
    // so the smoke test must not depend on the "Dashboard" nav item.
    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(
      find.text('LIVE MARKET INTELLIGENCE · ENGINE CONNECTED'),
      findsOneWidget,
    );
    expect(find.text('TRADE ENGINE'), findsOneWidget);
    expect(find.text('Waiting for connected market data...'), findsOneWidget);
  });
}
