import 'package:flutter_test/flutter_test.dart';
import 'package:master_trading_engine/app/live_intelligence.dart';

void main(){
  test('live intelligence calculates indicators from valid candles',(){
    final candles=List.generate(60,(i)=>LiveCandle(100+i.toDouble(),102+i.toDouble(),99+i.toDouble(),101+i.toDouble(),1000.0));
    final result=const LiveMarketIntelligence().calculate(candles);
    expect(result.ema20,greaterThan(result.ema50));
    expect(result.rsi14,greaterThan(90));
    expect(result.atr14,greaterThan(0));
  });
}
