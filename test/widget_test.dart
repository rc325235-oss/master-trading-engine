import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/app.dart';

void main() {
  testWidgets('paper-safe app starts', (tester) async {
    await tester.pumpWidget(const MasterTradingEngineApp());
    expect(find.text('AUTO-TRADING LOCKED'), findsOneWidget);
    expect(find.text('Backtest'), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);
  });
}
