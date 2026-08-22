import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/integrated.dart';

void main() {
  test('master trading engine analysis smoke test', () {
    final candles = List<Candle>.generate(
      40,
      (i) {
        final close = 100.0 + i;
        return Candle(close - 0.5, close + 1.0, close - 1.0, close, 1000.0 + i);
      },
    );

    final result = analyze(candles);

    expect(result.ema20, greaterThan(0));
    expect(result.ema50, greaterThan(0));
    expect(result.ema200, greaterThan(0));
    expect(result.atr, greaterThan(0));
    expect(result.support, lessThanOrEqualTo(result.resistance));
    expect(result.buyer + result.seller, equals(100));
    expect(result.score, inInclusiveRange(0, 100));
  });
}
