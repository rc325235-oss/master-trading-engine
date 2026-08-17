import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/risk_engine.dart';
import 'package:master_trading_engine/app/trade_favorability.dart';

void main() {
  test('long risk plan produces valid targets and R:R', () {
    final plan = const RiskEngine().build(
      direction: 'LONG',
      price: 100,
      atr: 2,
      support: 98,
      resistance: 105,
      fairValue: 103,
    );
    expect(plan.stopLoss, lessThan(plan.entry));
    expect(plan.target1, greaterThan(plan.entry));
    expect(plan.target2, greaterThan(plan.target1));
    expect(plan.rewardToTarget1, greaterThan(0));
  });

  test('favorability consumes computed R:R', () {
    final engine = const TradeFavorabilityEngine();
    final high = engine.calculate(
      direction: 'LONG', bullishTrend: true, bearishTrend: false,
      price: 100, ema20: 99, ema50: 97, ema200: 90, rsi: 60,
      volumeRatio: 1.5, support: 98, resistance: 105,
      breakoutUp: true, breakoutDown: false, atr: 2, rr1: 2,
    );
    final low = engine.calculate(
      direction: 'LONG', bullishTrend: true, bearishTrend: false,
      price: 100, ema20: 99, ema50: 97, ema200: 90, rsi: 60,
      volumeRatio: 1.5, support: 98, resistance: 105,
      breakoutUp: true, breakoutDown: false, atr: 2, rr1: 0.8,
    );
    expect(high.overall, greaterThan(low.overall));
    expect(high.factors.last.name, 'Risk / Reward');
  });
}
