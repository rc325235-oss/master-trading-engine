import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'live_intelligence.dart';
import 'fair_value.dart';
import 'trade_favorability.dart';
import 'risk_engine.dart';
import 'master_decision_engine.dart';

class Candle { final double o,h,l,c,v; const Candle(this.o,this.h,this.l,this.c,this.v); }

class IntegratedApp extends StatelessWidget {
  const IntegratedApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,title:'Master Trading Engine',theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,colorSchemeSeed:Colors.amber),home:const Home());
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState()=>_HomeState(); }
class _HomeState extends State<Home> {
  final symbol=TextEditingController(text:'BTCUSDT');
  String tf='5m',error=''; bool loading=false; Timer? timer;
  List<Candle> candles=[]; IndicatorSnapshot? indicators; LiveSignal? signal; FairValueResult? fair; RiskPlan? risk; TradeFavorabilityResult? favor; MasterDecision? master;

  @override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:30),(_){if(mounted&&!loading)load();});}
  @override void dispose(){timer?.cancel();symbol.dispose();super.dispose();}

  Future<void> load() async {
    if(loading)return;
    setState(()=>loading=true);
    try {
      final s=symbol.text.trim().toUpperCase();
      final uri=Uri.parse('https://api.binance.com/api/v3/klines?symbol=$s&interval=$tf&limit=250');
      final response=await http.get(uri).timeout(const Duration(seconds:8));
      if(response.statusCode!=200)throw Exception('HTTP ${response.statusCode}');
      final raw=jsonDecode(response.body) as List;
      final data=raw.map((x)=>Candle(double.parse(x[1]),double.parse(x[2]),double.parse(x[3]),double.parse(x[4]),double.parse(x[5]))).toList();
      if(data.length<30)throw Exception('Insufficient candles');
      final input=data.map((x)=>LiveCandle(x.o,x.h,x.l,x.c,x.v)).toList();
      final li=const LiveMarketIntelligence();
      final ind=li.calculate(input); final sig=li.analyze(input);
      final fv=const FairValueEngine().calculate(current:data.last.c,ema20:ind.ema20,ema50:ind.ema50,ema200:ind.ema200,support:ind.support,resistance:ind.resistance,rsi:ind.rsi14,atr:ind.atr14);
      final rp=const RiskEngine().build(direction:sig.direction,price:data.last.c,atr:ind.atr14,support:ind.support,resistance:ind.resistance,fairValue:fv.fairValue);
      final tfv=const TradeFavorabilityEngine().calculate(direction:sig.direction,bullishTrend:ind.bullishTrend,bearishTrend:ind.bearishTrend,price:data.last.c,ema20:ind.ema20,ema50:ind.ema50,ema200:ind.ema200,rsi:ind.rsi14,volumeRatio:ind.volumeRatio,support:ind.support,resistance:ind.resistance,breakoutUp:sig.breakoutUp,breakoutDown:sig.breakoutDown,atr:ind.atr14,rr1:rp.rewardToTarget1);
      final md=const MasterDecisionEngine().evaluate(direction:sig.direction,regime:sig.regime,price:data.last.c,atr:ind.atr14,rsi:ind.rsi14,volumeRatio:ind.volumeRatio,ema20:ind.ema20,ema50:ind.ema50,ema200:ind.ema200,breakoutUp:sig.breakoutUp,breakoutDown:sig.breakoutDown,risk:rp,capital:100000,riskPercent:1);
      if(!mounted)return;
      setState((){candles=data;indicators=ind;signal=sig;fair=fv;risk=rp;favor=tfv;master=md;error='';});
    } catch(e) {
      if(mounted)setState(()=>error='No reliable live feed: $e');
    } finally {
      if(mounted)setState(()=>loading=false);
    }
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('MASTER TRADING ENGINE'),actions:const [Padding(padding:EdgeInsets.all(8),child:Chip(label:Text('ANALYSIS ONLY')))]),body:ListView(padding:const EdgeInsets.all(10),children:_content()));
  }

  List<Widget> _content(){
    final widgets=<Widget>[_controls()];
    if(error.isNotEmpty)widgets.add(_section('⚠️ DATA STATUS',[error]));
    if(candles.isNotEmpty)widgets.add(Card(child:Padding(padding:const EdgeInsets.all(8),child:SizedBox(height:240,child:CustomPaint(painter:CandlePainter(candles))))));
    final m=master; final f=fair; final r=risk; final v=favor; final i=indicators; final s=signal;
    if(m!=null)widgets.add(_section('🔥 MASTER DECISION',['${m.decision}','Direction: ${m.direction}','Master Confidence: ${m.confidence}%','Regime: ${m.regime}','🟢 In favor: ${v?.inFavor??0}   🟡 Neutral: ${v?.neutral??0}   🔴 Against: ${v?.against??0}']));
    if(f!=null)widgets.add(_section('⚖️ FAIR VALUE ANALYSIS',['Current Price: ${f.currentPrice.toStringAsFixed(2)}','Fair Value: ${f.fairValue.toStringAsFixed(2)}','Fair Value Zone: ${f.zoneLow.toStringAsFixed(2)} – ${f.zoneHigh.toStringAsFixed(2)}','Distance: ${f.distancePercent.toStringAsFixed(2)}%','Status: ${f.status}','Confidence: ${f.confidence}%',...f.factors.map((x)=>'• $x')]));
    if(v!=null)widgets.add(_section('🔥 TRADE FAVORABILITY',['${v.overall}% IN YOUR FAVOR','${v.inFavor} factors in favor • ${v.neutral} neutral • ${v.against} against',...v.factors.map((x)=>'${x.score>=70?'🟢':x.score>=50?'🟡':'🔴'} ${x.name}: ${x.score}% — ${x.detail}')]));
    if(m!=null)widgets.add(_section('🧠 STRATEGY CONFLUENCE',m.strategies.map((x)=>'${x.name}: ${x.score}% — ${x.detail}').toList()));
    if(r!=null)widgets.add(_section('🛡️ RISK / REWARD',['Direction: ${r.direction}','Entry: ${r.entry.toStringAsFixed(2)}','Stop Loss: ${r.stopLoss.toStringAsFixed(2)}','Target 1: ${r.target1.toStringAsFixed(2)} • R:R ${r.rewardToTarget1.toStringAsFixed(2)}','Target 2: ${r.target2.toStringAsFixed(2)} • R:R ${r.rewardToTarget2.toStringAsFixed(2)}','Risk/Unit: ${r.riskPerUnit.toStringAsFixed(2)}']));
    if(m!=null)widgets.add(_section('📐 POSITION SIZING',['Illustrative capital: ₹100000','Risk budget: ${m.riskAmount.toStringAsFixed(2)}','Calculated quantity: ${m.positionSize.toStringAsFixed(6)}']));
    if(i!=null)widgets.add(_section('📈 LIVE TECHNICALS',['Regime: ${s?.regime}','Direction: ${s?.direction}','EMA20: ${i.ema20.toStringAsFixed(2)}','EMA50: ${i.ema50.toStringAsFixed(2)}','EMA200: ${i.ema200.toStringAsFixed(2)}','RSI: ${i.rsi14.toStringAsFixed(1)}','ATR: ${i.atr14.toStringAsFixed(2)}','Volume Ratio: ${i.volumeRatio.toStringAsFixed(2)}x','Support: ${i.support.toStringAsFixed(2)}','Resistance: ${i.resistance.toStringAsFixed(2)}']));
    widgets.add(const Card(child:ListTile(leading:Icon(Icons.shield),title:Text('SAFETY LOCK'),subtitle:Text('Analysis and paper-trading logic only. No live broker order is executed.'))));
    return widgets;
  }

  Widget _controls()=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:symbol,decoration:const InputDecoration(labelText:'Symbol',border:OutlineInputBorder()))),const SizedBox(width:8),DropdownButton<String>(value:tf,items:const ['1m','3m','5m','15m','1h','4h'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x){if(x!=null)setState(()=>tf=x);}),IconButton(onPressed:loading?null:load,icon:const Icon(Icons.refresh))]));
  Widget _section(String title,List<String> lines)=>Card(child:ExpansionTile(title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),children:[Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),child:Align(alignment:Alignment.centerLeft,child:Text(lines.join('\n\n'))))]));
}

class CandlePainter extends CustomPainter {
  final List<Candle> data; CandlePainter(this.data);
  @override void paint(Canvas canvas,Size size){final d=data.length>80?data.sublist(data.length-80):data;final hi=d.map((x)=>x.h).reduce((a,b)=>a>b?a:b);final lo=d.map((x)=>x.l).reduce((a,b)=>a<b?a:b);final range=hi==lo?1.0:hi-lo;final w=size.width/d.length;final p=Paint()..strokeWidth=1;double y(double value)=>size.height-(value-lo)/range*size.height;for(var n=0;n<d.length;n++){final k=d[n];final x=n*w+w/2;p.color=k.c>=k.o?Colors.greenAccent:Colors.redAccent;canvas.drawLine(Offset(x,y(k.h)),Offset(x,y(k.l)),p);canvas.drawRect(Rect.fromLTRB(x-w*.3,y(k.o>k.c?k.o:k.c),x+w*.3,y(k.o<k.c?k.o:k.c)),p);}}
  @override bool shouldRepaint(covariant CandlePainter oldDelegate)=>oldDelegate.data!=data;
}
