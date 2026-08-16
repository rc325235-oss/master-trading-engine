import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with safety lock', (tester) async {
    await tester.pumpWidget(const IntegratedApp());
    expect(find.text('AUTO-TRADING LOCKED'), findsOneWidget);
    expect(find.text('Live AI'), findsOneWidget);
    expect(find.text('Backtest'), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
  });
}
