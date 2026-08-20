import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with current dashboard', (tester) async {
    await tester.pumpWidget(const IntegratedApp());

    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(find.text('LIVE MARKET INTELLIGENCE · ENGINE CONNECTED'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Live Market'), findsOneWidget);
    expect(find.text('AI Analysis'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('AI Strategy'), findsOneWidget);
    expect(find.text('Backtest'), findsOneWidget);
    expect(find.text('Paper Trading'), findsOneWidget);
  });
}
