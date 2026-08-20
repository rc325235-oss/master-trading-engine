import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  testWidgets('integrated app starts with current dashboard', (tester) async {
    // The dashboard sidebar is intentionally shown on tablet/desktop widths.
    // Flutter's default test viewport is narrower, so explicitly use a
    // desktop-sized surface for this dashboard smoke test.
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const IntegratedApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MASTER TRADING ENGINE'), findsOneWidget);
    expect(
      find.text('LIVE MARKET INTELLIGENCE · ENGINE CONNECTED'),
      findsOneWidget,
    );
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Live Market'), findsOneWidget);
    expect(find.text('AI Analysis'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('AI Strategy'), findsOneWidget);
    expect(find.text('Backtest'), findsOneWidget);
    expect(find.text('Paper Trading'), findsOneWidget);
  });
}
