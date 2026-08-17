import 'risk_engine.dart';

class PaperTradeProposal {
  final String symbol, direction, status;
  final double entry, stopLoss, target1, target2, riskReward1, riskReward2;
  const PaperTradeProposal({required this.symbol,required this.direction,required this.status,required this.entry,required this.stopLoss,required this.target1,required this.target2,required this.riskReward1,required this.riskReward2});
}

class PaperTradeBridge {
  const PaperTradeBridge();
  PaperTradeProposal create({required String symbol, required RiskPlan risk}) => PaperTradeProposal(symbol:symbol,direction:risk.direction,status:'SIMULATION ONLY — NOT EXECUTED',entry:risk.entry,stopLoss:risk.stopLoss,target1:risk.target1,target2:risk.target2,riskReward1:risk.rewardToTarget1,riskReward2:risk.rewardToTarget2);
}
