import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Candle { final double o,h,l,c,v; const Candle(this.o,this.h,this.l,this.c,this.v); }
class Analysis {
  final String regime, decision, psychology, direction; final int score,buyer,seller; final double rsi,ema20,ema50,ema200,atr,support,resistance; final bool trend,breakout;
  const Analysis({required this.regime,required this.decision,required this.psychology,required this.direction,required this.score,required this.buyer,required this.seller,required this.rsi,required this.ema20,required this.ema50,required this.ema200,required this.atr,required this.support,required this.resistance,required this.trend,required this.breakout});
}

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends State<Dashboard> {
  final symbol=TextEditingController(text:'BTCUSDT'); String interval='5m'; bool live=false,loading=false; String error=''; Timer? timer; List<Candle> candles=[]; Analysis? analysis;
  @override void dispose(){timer?.cancel();symbol.dispose();super.dispose();}
  Future<void> refresh() async {
    if(loading)return; setState(()=>loading=true);
    try {
      final s=symbol.text.trim().toUpperCase();
      final uri=Uri.parse('https://api.binance.com/api/v3/klines?symbol=$s&interval=$interval&limit=200');
      final res=await http.get(uri).timeout(const Duration(seconds:8));
      if(res.statusCode!=200)throw Exception('HTTP ${res.statusCode}');
      final raw=jsonDecode(res.body) as List;
      final data=raw.map((x)=>Candle(double.parse(x[1]),double.parse(x[2]),double.parse(x[3]),double.parse(x[4]),double.parse(x[5]))).toList();
      if(!mounted)return; setState((){candles=data;analysis=analyze(data);error='';});
    }catch(e){if(mounted)setState(()=>error='Live feed error: $e');}finally{if(mounted)setState(()=>loading=false);}
  }
  void setLive(bool value){timer?.cancel();setState(()=>live=value);if(value){refresh();timer=Timer.periodic(const Duration(seconds:15),(_)=>refresh());}}
  @override Widget build(BuildContext context){
    final children=<Widget>[
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
        Row(children:[Expanded(child:TextField(controller:symbol,decoration:const InputDecoration(labelText:'Market Symbol',hintText:'BTCUSDT',border:OutlineInputBorder()))),const SizedBox(width:8),DropdownButton<String>(value:interval,items:const ['1m','5m','15m','1h','4h'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState(()=>interval=v);})]),
        const SizedBox(height:10),Row(children:[Expanded(child:FilledButton.icon(onPressed:loading?null:refresh,icon:const Icon(Icons.analytics),label:Text(loading?'ANALYZING...':'ANALYZE MARKET'))),const SizedBox(width:8),FilterChip(selected:live,onSelected:setLive,label:Text(live?'LIVE ON':'LIVE OFF'))])
      ]))),
    ];
    if(error.isNotEmpty)children.add(Card(child:ListTile(leading:const Icon(Icons.warning),title:const Text('Market feed error'),subtitle:Text(error))));
    if(candles.isNotEmpty)children.add(Card(child:Padding(padding:const EdgeInsets.all(8),child:SizedBox(height:240,child:CustomPaint(painter:CandlePainter(candles))))));
    final a=analysis;
    if(a==null){children.add(const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Press ANALYZE MARKET. The default public feed is Binance candles. Auto-trading is permanently locked.'))));}
    else {
      children.add(Card(color:a.score>=85?Colors.green.shade900:Colors.blueGrey.shade900,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.decision,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text('Score ${a.score}/100  •  ${a.direction}  •  ${a.regime}'),const SizedBox(height:6),Text(a.psychology)]))));
      children.add(section('STRATEGIES',[metric('Trend Rider',a.trend?'VALID':'WAIT'),metric('Breakout + Momentum',a.breakout?'VALID':'WAIT'),metric('Direction',a.direction),metric('Regime',a.regime)]));
      children.add(section('MARKET PSYCHOLOGY',[metric('Buyer Strength','${a.buyer}/100'),metric('Seller Strength','${a.seller}/100'),metric('Psychology',a.psychology)]));
      children.add(section('TECHNICALS',[metric('RSI',a.rsi.toStringAsFixed(1)),metric('EMA 20',a.ema20.toStringAsFixed(2)),metric('EMA 50',a.ema50.toStringAsFixed(2)),metric('EMA 200',a.ema200.toStringAsFixed(2)),metric('Support',a.support.toStringAsFixed(2)),metric('Resistance',a.resistance.toStringAsFixed(2)),metric('ATR',a.atr.toStringAsFixed(2))]));
      children.add(const Card(child:ListTile(leading:Icon(Icons.shield),title:Text('Risk Gate'),subtitle:Text('Analysis only. No broker orders. A setup must be independently verified before any real-money decision.'))));
    }
    return Scaffold(body:RefreshIndicator(onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(12),children:children)));
  }
  Widget section(String title,List<Widget> items)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:items)])));
  Widget metric(String k,String v)=>Container(constraints:const BoxConstraints(minWidth:120,maxWidth:270),padding:const EdgeInsets.all(10),decoration:BoxDecoration(border:Border.all(color:Colors.white24),borderRadius:BorderRadius.circular(10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(k,style:const TextStyle(color:Colors.white60,fontSize:12)),Text(v,style:const TextStyle(fontWeight:FontWeight.bold))]));
}

Analysis analyze(List<Candle> c){
  final close=c.map((x)=>x.c).toList(); final high=c.map((x)=>x.h).toList(); final low=c.map((x)=>x.l).toList();
  double ema(int n){var e=close.first;final k=2/(n+1);for(final p in close.skip(1)){e=p*k+e*(1-k);}return e;}
  double rsi(){var gain=0.0,loss=0.0;final n=math.min(14,close.length-1);for(var i=close.length-n;i<close.length;i++){final d=close[i]-close[i-1];if(d>=0)gain+=d;else loss-=d;}if(loss==0)return 100;return 100-(100/(1+gain/loss));}
  double atr(){var sum=0.0;final n=math.min(14,c.length-1);for(var i=c.length-n;i<c.length;i++){sum+=math.max(c[i].h-c[i].l,math.max((c[i].h-c[i-1].c).abs(),(c[i].l-c[i-1].c).abs()));}return sum/n;}
  final e20=ema(20),e50=ema(50),e200=ema(200),rr=rsi(),at=atr(),last=close.last;final start=math.max(0,c.length-21);final resistance=high.sublist(start).reduce(math.max),support=low.sublist(start).reduce(math.min);final avgVol=c.sublist(start).map((x)=>x.v).reduce((a,b)=>a+b)/c.sublist(start).length;final vol=c.last.v;
  final bull=e20>e50&&e50>e200&&last>e20&&rr>=52;final bear=e20<e50&&e50<e200&&last<e20&&rr<=48;final breakUp=last>resistance-at*.15&&vol>avgVol*1.25;final breakDown=last<support+at*.15&&vol>avgVol*1.25;final trend=bull||bear,breakout=breakUp||breakDown;final direction=(bull||breakUp)?'LONG':(bear||breakDown)?'SHORT':'NEUTRAL';final regime=trend?'TREND':breakout?'BREAKOUT':'RANGE / UNCLEAR';
  var score=35;if(trend)score+=20;if(breakout)score+=20;if(vol>avgVol*1.15)score+=8;if((direction=='LONG'&&rr>52)||(direction=='SHORT'&&rr<48))score+=7;if(direction=='NEUTRAL')score=math.min(score,59);score=math.min(100,score);
  final buyer=math.max(5,math.min(95,(50+(rr-50)*1.4+(bull?18:0)+(breakUp?15:0)+(vol>avgVol*1.25?8:0)).round()));final seller=100-buyer;
  String psych;if(direction=='LONG'){psych=breakUp?'Buyers are aggressive; breakout-chasing risk is elevated. Wait for confirmation/retest.':'Buyers have structural control; pullback risk remains.';}else if(direction=='SHORT'){psych=breakDown?'Sellers are aggressive; breakdown-chasing risk is elevated. Wait for confirmation/retest.':'Sellers have structural control; short-covering risk remains.';}else{psych='No clean participant edge. Avoid forcing a trade.';}
  final decision=score>=85?'🔥 HOT TRADE CANDIDATE':score>=75?'🟢 STRONG SETUP':score>=60?'🟡 WATCH':'🔴 NO TRADE';
  return Analysis(regime:regime,decision:decision,psychology:psych,direction:direction,score:score,buyer:buyer,seller:seller,rsi:rr,ema20:e20,ema50:e50,ema200:e200,atr:at,support:support,resistance:resistance,trend:trend,breakout:breakout);
}
class CandlePainter extends CustomPainter { final List<Candle> data; CandlePainter(this.data); @override void paint(Canvas canvas,Size size){final n=math.min(80,data.length);final d=data.sublist(data.length-n);final hi=d.map((x)=>x.h).reduce(math.max),lo=d.map((x)=>x.l).reduce(math.min);final range=(hi-lo)==0?1:hi-lo;final w=size.width/n;final p=Paint()..strokeWidth=1.2;for(var i=0;i<n;i++){final k=d[i],x=i*w+w/2;double y(double v)=>size.height-(v-lo)/range*size.height;p.color=k.c>=k.o?Colors.greenAccent:Colors.redAccent;canvas.drawLine(Offset(x,y(k.h)),Offset(x,y(k.l)),p);final top=y(math.max(k.o,k.c)),bottom=y(math.min(k.o,k.c));canvas.drawRect(Rect.fromLTWH(x-w*.3,top,w*.6,math.max(1,bottom-top)),p);}}@override bool shouldRepaint(covariant CandlePainter oldDelegate)=>oldDelegate.data!=data;}
