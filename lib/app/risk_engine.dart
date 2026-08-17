import 'dart:math' as math;

class RiskPlan {
  final double entry, stopLoss, target1, target2, riskPerUnit, rewardToTarget1, rewardToTarget2;
  final String direction, status;
  const RiskPlan({required this.entry,required this.stopLoss,required this.target1,required this.target2,required this.riskPerUnit,required this.rewardToTarget1,required this.rewardToTarget2,required this.direction,required this.status});
}

class RiskEngine {
  const RiskEngine();
  RiskPlan build({required String direction, required double price, required double atr, required double support, required double resistance, required double fairValue}) {
    final unit = math.max(atr, price * 0.003);
    if (direction == 'LONG') {
      final sl = math.min(support - unit * .15, price - unit * 1.2);
      final risk = price - sl;
      final t1 = math.max(price + risk * 1.5, fairValue);
      final t2 = price + risk * 2.5;
      return RiskPlan(entry:price,stopLoss:sl,target1:t1,target2:t2,riskPerUnit:risk,rewardToTarget1:(t1-price)/risk,rewardToTarget2:(t2-price)/risk,direction:direction,status:'PAPER / ANALYSIS ONLY');
    }
    if (direction == 'SHORT') {
      final sl = math.max(resistance + unit * .15, price + unit * 1.2);
      final risk = sl - price;
      final t1 = math.min(price - risk * 1.5, fairValue);
      final t2 = price - risk * 2.5;
      return RiskPlan(entry:price,stopLoss:sl,target1:t1,target2:t2,riskPerUnit:risk,rewardToTarget1:(price-t1)/risk,rewardToTarget2:(price-t2)/risk,direction:direction,status:'PAPER / ANALYSIS ONLY');
    }
    return RiskPlan(entry:price,stopLoss:price,target1:price,target2:price,riskPerUnit:0,rewardToTarget1:0,rewardToTarget2:0,direction:direction,status:'NO TRADE');
  }
}
