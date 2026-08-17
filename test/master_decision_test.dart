import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/master_decision_engine.dart';
import 'package:master_trading_engine/app/risk_engine.dart';

void main() {
  test('master decision sizes position from risk budget', () {
    final risk = const RiskEngine().build(
      direction: 'LONG', price: 100, atr: 2, support: 98,
      resistance: 105, fairValue: 103,
    );
    final result = const MasterDecisionEngine().evaluate(
      direction: 'LONG', regime: 'TREND', price: 100, atr: 2, rsi: 60,
      volumeRatio: 1.5, ema20: 99, ema50: 97, ema200: 90,
      breakoutUp: true, breakoutDown: false, risk: risk,
      capital: 100000, riskPercent: 1,
    );
    expect(result.riskAmount, 1000);
    expect(result.positionSize, greaterThan(0));
  });

  test('paper position closes at stop and records pnl', () {
    final p = PaperPosition(symbol: 'TEST', direction: 'LONG', quantity: 10,
        entry: 100, stopLoss: 95, target1: 105, target2: 110);
    p.evaluate(95);
    expect(p.closed, isTrue);
    expect(p.exitReason, 'STOP LOSS');
    expect(p.pnl, -50);
  });
}
