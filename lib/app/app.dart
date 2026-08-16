import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Candle { final double o,h,l,c,v; Candle(this.o,this.h,this.l,this.c,this.v); }

class Analysis {
  final String regime, decision, psychology, direction;
  final int score, buyer, seller;
  final double rsi, ema20, ema50, ema200, atr, support, resistance;
  final bool trend, breakout;
  const Analysis({required this.regime,required this.decision,required this.psychology,required this.direction,required this.score,required this.buyer,required this.seller,required this.rsi,required this.ema20,required this.ema50,required this.ema200,required this.atr,required this.support,required this.resistance,required this.trend,required this.breakout});
}

class MasterTradingEngineApp extends StatelessWidget {
  const MasterTradingEngineApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,title:'Master Trading Engine',theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.amber,brightness:Brightness.dark),home:const Dashboard());
}

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends State<Dashboard> {
  final symbol=TextEditingController(text:'BTCUSDT');
  String interval='5m'; Timer? timer; bool live=false, loading=false; String error=''; List<Candle> candles=[]; Analysis? a;
  @override void dispose(){timer?.cancel();symbol.dispose();super.dispose();}
  Future<void> refresh() async {
    if(loading)return; setState(()=>loading=true);
    try {
      final s=symbol.text.trim().toUpperCase();
      final url=Uri.parse('https://api.binance.com/api/v3/klines?symbol=$s&interval=$interval&limit=200');
      final r=await http.get(url).timeout(const Duration(seconds:8));
      if(r.statusCode!=200) throw Exception('Market data unavailable (${r.statusCode})');
      final raw=jsonDecode(r.body) as List;
      final cs=raw.map((x)=>Candle(double.parse(x[1]),double.parse(x[2]),double.parse(x[3]),double.parse(x[4]),double.parse(x[5]))).toList();
      setState((){candles=cs;a=analyze(cs);error='';});
    }catch(e){setState(()=>error='Live data error: $e');}finally{if(mounted)setState(()=>loading=false);}
  }
  void toggleLive(){setState(()=>live=!live);timer?.cancel();if(live){refresh();timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());}}
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('MASTER TRADING ENGINE'),actions:[Padding(padding:const EdgeInsets.all(8),child:Chip(label:Text('AUTO-TRADING LOCKED'),avatar:const Icon(Icons.lock,size:16)))]),body:RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Row(children:[Expanded(child:TextField(controller:symbol,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Market Symbol',hintText:'BTCUSDT',border:OutlineInputBorder()))),const SizedBox(width:8),DropdownButton<String>(value:interval,items:const ['1m','5m','15m','1h','4h'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState(()=>interval=v);})]),const SizedBox(height:10),Row(children:[Expanded(child:FilledButton.icon(onPressed:loading?null:refresh,icon:const Icon(Icons.refresh),label:Text(loading?'ANALYZING...':'ANALYZE LIVE MARKET'))),const SizedBox(width:8),FilterChip(selected:live,onSelected:(_)=>toggleLive(),label:Text(live?'LIVE ON':'LIVE OFF'),avatar:Icon(live?Icons.wifi:Icons.wifi_off))])])),
      if(error.isNotEmpty)Card(child:ListTile(leading:const Icon(Icons.warning),title:const Text('Market feed'),subtitle:Text(error))),
      if(candles.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(8),child:SizedBox(height:240,child:CustomPaint(painter:CandlePainter(candles))))),
      if(a!=null)...[
        _hero(a!),
        _section('STRATEGY ANALYSIS',[metric('Trend Rider',a!.trend?'VALID':'WAIT'),metric('Breakout + Momentum',a!.breakout?'VALID':'WAIT'),metric('Market Regime',a!.regime),metric('Direction',a!.direction)]),
        _section('MARKET PSYCHOLOGY',[metric('Buyer Strength','${a!.buyer}/100'),metric('Seller Strength','${a!.seller}/100'),metric('Psychology',a!.psychology)]),
        _section('TECHNICAL ANALYSIS',[metric('RSI',a!.rsi.toStringAsFixed(1)),metric('EMA 20',a!.ema20.toStringAsFixed(2)),metric('EMA 50',a!.ema50.toStringAsFixed(2)),metric('EMA 200',a!.ema200.toStringAsFixed(2)),metric('Support',a!.support.toStringAsFixed(2)),metric('Resistance',a!.resistance.toStringAsFixed(2)),metric('ATR',a!.atr.toStringAsFixed(2))]),
        _section('RISK GATE',[const Text('No automatic broker execution. Any suggested setup must be independently verified. SL/target are analytical levels, not guarantees.')]),
      ] else const Card(child:Padding(padding:EdgeInsets.all(20),child:Column(children:[Icon(Icons.analytics,size:48),SizedBox(height:8),Text('Connect to live market data and press ANALYZE LIVE MARKET.'),SizedBox(height:4),Text('Default feed: Binance public candles. Auto-trading remains locked.')]))),
      const SizedBox(height:20),const Text('Backtest and Paper Trading are available in the next integrated tabs once the live analyzer is verified.',style:TextStyle(color:Colors.white60))
    ])));
  }
  Widget _hero(Analysis x)=>Card(color:x.score>=85?Colors.green.shade900:x.score>=75?Colors.blueGrey.shade900:Colors.grey.shade900,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.decision,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text('HOT TRADE SCORE  ${x.score}/100',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text('Regime: ${x.regime}  •  Direction: ${x.direction}'),const SizedBox(height:5),Text(x.psychology)])));
  Widget _section(String title,List<Widget> children)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:children)])));
  Widget metric(String k,String v)=>Container(padding:const EdgeInsets.all(10),constraints:const BoxConstraints(minWidth:120,maxWidth:260),decoration:BoxDecoration(border:Border.all(color:Colors.white24),borderRadius:BorderRadius.circular(10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(k,style:const TextStyle(color:Colors.white60,fontSize:12)),const SizedBox(height:3),Text(v,style:const TextStyle(fontWeight:FontWeight.bold))]));
}

Analysis analyze(List<Candle> c){
  final closes=c.map((x)=>x.c).toList(), highs=c.map((x)=>x.h).toList(), lows=c.map((x)=>x.l).toList();
  double ema(int n){var e=closes.first, k=2/(n+1);for(final p in closes.skip(1)){e=p*k+e*(1-k);}return e;}
  final e20=ema(20),e50=ema(50),e200=ema(200),last=closes.last;
  double rsi(){var gain=0.0,loss=0.0;final n=math.min(14,closes.length-1);for(var i=closes.length-n;i<closes.length;i++){final d=closes[i]-closes[i-1];if(d>=0)gain+=d;else loss-=d;}if(loss==0)return 100;return 100-(100/(1+gain/loss));}
  final rr=rsi(); final recentHigh=highs.skip(math.max(0,highs.length-21)).reduce(math.max),recentLow=lows.skip(math.max(0,lows.length-21)).reduce(math.min);
  double atr(){var s=0.0;final n=math.min(14,c.length-1);for(var i=c.length-n;i<c.length;i++){s+=math.max(c[i].h-c[i].l,math.max((c[i].h-c[i-1].c).abs(),(c[i].l-c[i-1].c).abs()));}return s/n;}
  final at=atr(); final volAvg=c.skip(math.max(0,c.length-21)).map((x)=>x.v).reduce((a,b)=>a+b)/math.min(21,c.length);final vol=c.last.v;
  final bullish=e20>e50&&e50>e200&&last>e20&&rr>=52; final bearish=e20<e50&&e50<e200&&last<e20&&rr<=48;
  final breakoutUp=last>recentHigh-at*0.15&&vol>volAvg*1.25, breakoutDown=last<recentLow+at*0.15&&vol>volAvg*1.25;
  final trend=bullish||bearish, breakout=breakoutUp||breakoutDown; final dir=bullish||breakoutUp?'LONG':bearish||breakoutDown?'SHORT':'NEUTRAL';
  final regime=trend?'TREND':breakout?'BREAKOUT':'RANGE / UNCLEAR';
  var score=35;if(trend)score+=20;if(breakout)score+=20;if(vol>volAvg*1.15)score+=8;if((rr>52&&dir=='LONG')||(rr<48&&dir=='SHORT'))score+=7;if(dir=='NEUTRAL')score=math.min(score,59);score=math.min(100,score);
  final buyer=math.max(5,math.min(95,(50+(rr-50)*1.4+(bullish?18:0)+(breakoutUp?15:0)+(vol>volAvg*1.25?8:0)).round())); final seller=100-buyer;
  String psych;if(dir=='LONG')psych=breakoutUp?'Buyers are aggressive; breakout-chasing risk is elevated. Wait for confirmation/retest.':'Buyers have structural control; sellers appear weaker, but pullback risk remains.';else if(dir=='SHORT')psych=breakoutDown?'Sellers are aggressive; breakdown-chasing risk is elevated. Wait for confirmation/retest.':'Sellers have structural control; buyers appear weaker, but short-covering risk remains.';else psych='Neither side has a clean edge. Avoid forcing a trade while structure is unclear.';
  final decision=score>=85?'🔥 HOT TRADE CANDIDATE':score>=75?'🟢 STRONG SETUP':score>=60?'🟡 WATCH':'🔴 NO TRADE';
  return Analysis(regime:regime,decision:decision,psychology:psych,direction:dir,score:score,buyer:buyer,seller:seller,rsi:rr,ema20:e20,ema50:e50,ema200:e200,atr:at,support:recentLow,resistance:recentHigh,trend:trend,breakout:breakout);
}

class CandlePainter extends CustomPainter { final List<Candle> c; CandlePainter(this.c); @override void paint(Canvas canvas,Size s){final n=math.min(80,c.length);final data=c.sublist(c.length-n);final hi=data.map((x)=>x.h).reduce(math.max),lo=data.map((x)=>x.l).reduce(math.min);final range=(hi-lo)==0?1:hi-lo;final w=s.width/n;final paint=Paint()..strokeWidth=1.2;for(var i=0;i<n;i++){final x=i*w+w/2, k=data[i];double y(double p)=>s.height-(p-lo)/range*s.height;paint.color=k.c>=k.o?Colors.greenAccent:Colors.redAccent;canvas.drawLine(Offset(x,y(k.h)),Offset(x,y(k.l)),paint);final top=y(math.max(k.o,k.c)),bot=y(math.min(k.o,k.c));canvas.drawRect(Rect.fromLTWH(x-w*.32,top,w*.64,math.max(1,bot-top)),paint);}}@override bool shouldRepaint(covariant CandlePainter old)=>old.c!=c;}
