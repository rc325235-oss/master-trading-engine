import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts in analysis-only mode', (tester) async {
    await tester.pumpWidget(const IntegratedApp());
    await tester.pumpAndSettle();

    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(find.text('ANALYSIS ONLY'), findsOneWidget);
    expect(find.text('SAFETY LOCK'), findsOneWidget);
    expect(find.text('AUTO-TRADING LOCKED'), findsNothing);
  });
}
