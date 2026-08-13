import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/app.dart';

void main() {
  testWidgets('paper-safe app starts', (tester) async {
    await tester.pumpWidget(const MasterTradingEngineApp());
    expect(find.text('AUTO-TRADING LOCKED'), findsOneWidget);
    expect(find.text('Backtest'), findsOneWidget);
    expect(find.text('Paper'), findsOneWidget);
  });

  testWidgets('paper target closes position and does not auto-reenter', (tester) async {
    await tester.pumpWidget(const MasterTradingEngineApp());
    await tester.tap(find.text('Paper'));
    await tester.pumpAndSettle();

    final priceField = find.byType(TextField);
    expect(priceField, findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.tap(find.text('Process Tick'));
    await tester.pump();
    expect(find.text('LONG @ 100.00'), findsOneWidget);

    await tester.enterText(priceField, '102');
    await tester.tap(find.text('Process Tick'));
    await tester.pump();
    expect(find.text('TARGET HIT — CLOSED @ 102.00 | P&L ₹2.00'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('₹2.00'), findsOneWidget);

    await tester.enterText(priceField, '104');
    await tester.tap(find.text('Process Tick'));
    await tester.pump();
    expect(find.text('NO POSITION — WAITING FOR NEW SIGNAL'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('₹2.00'), findsOneWidget);
  });
}
