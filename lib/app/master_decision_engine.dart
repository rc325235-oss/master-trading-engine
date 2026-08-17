import 'dart:math' as math;
import 'risk_engine.dart';

class StrategyScore { final String name, detail; final int score; const StrategyScore(this.name,this.score,this.detail); }

class MasterDecision {
  final String direction, regime, decision;
  final int confidence;
  final List<StrategyScore> strategies;
  final double positionSize, riskAmount;
  const MasterDecision({required this.direction,required this.regime,required this.decision,required this.confidence,required this.strategies,required this.positionSize,required this.riskAmount});
}

class MasterDecisionEngine {
  const MasterDecisionEngine();

  MasterDecision evaluate({required String direction,required String regime,required double price,required double atr,required double rsi,required double volumeRatio,required double ema20,required double ema50,required double ema200,required bool breakoutUp,required bool breakoutDown,required RiskPlan risk,required double capital,required double riskPercent}) {
    final trend = direction=='LONG' && ema20>ema50 && ema50>ema200 || direction=='SHORT' && ema20<ema50 && ema50<ema200 ? 90 : 45;
    final breakout = (direction=='LONG'&&breakoutUp)||(direction=='SHORT'&&breakoutDown) ? 95 : 40;
    final meanReversion = direction=='LONG' ? (rsi<45?78: rsi>72?35:58) : direction=='SHORT' ? (rsi>55?78: rsi<28?35:58) : 50;
    final momentum = volumeRatio>=1.25 ? 84 : 55;
    final strategyScores=[
      StrategyScore('Trend Rider',trend,'EMA 20/50/200 directional alignment.'),
      StrategyScore('Breakout / Momentum',breakout,'Breakout and volume confirmation.'),
      StrategyScore('Mean Reversion',meanReversion,'RSI location used as a reversion context, not a standalone signal.'),
      StrategyScore('Momentum Confirmation',momentum,'Volume participation relative to recent average.'),
    ];
    final avg=(strategyScores.map((s)=>s.score).reduce((a,b)=>a+b)/strategyScores.length).round();
    final validDirection=direction!='NEUTRAL' && risk.riskPerUnit>0;
    final rrOk=risk.rewardToTarget1>=1.5;
    final finalConfidence=(avg+(rrOk?8:-12)+(regime=='RANGE'&&direction!='NEUTRAL'?-8:0)).clamp(0,100).toInt();
    final decision=!validDirection||!rrOk?'NO TRADE':finalConfidence>=80?'STRONG SETUP':finalConfidence>=65?'WAIT FOR CONFIRMATION':'NO TRADE';
    final riskAmount=capital*math.max(0,riskPercent)/100;
    final size=risk.riskPerUnit>0?riskAmount/risk.riskPerUnit:0;
    return MasterDecision(direction:direction,regime:regime,decision:decision,confidence:finalConfidence,strategies:strategyScores,positionSize:size,riskAmount:riskAmount);
  }
}

class PaperPosition { final String symbol,direction; final double quantity,entry,stopLoss,target1,target2; final DateTime openedAt; bool closed=false; double? exitPrice; DateTime? closedAt; String? exitReason;
  PaperPosition({required this.symbol,required this.direction,required this.quantity,required this.entry,required this.stopLoss,required this.target1,required this.target2,DateTime? openedAt}):openedAt=openedAt??DateTime.now();
  void evaluate(double price,{DateTime? now}) { if(closed)return; final hitStop=direction=='LONG'?price<=stopLoss:price>=stopLoss; final hitT2=direction=='LONG'?price>=target2:price<=target2; final hitT1=direction=='LONG'?price>=target1:price<=target1; if(hitStop||hitT2||hitT1){closed=true;exitPrice=price;closedAt=now??DateTime.now();exitReason=hitStop?'STOP LOSS':hitT2?'TARGET 2':'TARGET 1';} }
  double get pnl { if(exitPrice==null)return 0; return direction=='LONG'?(exitPrice!-entry)*quantity:(entry-exitPrice!)*quantity; }
}
