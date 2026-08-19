import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const bg = Color(0xFF050A11);
const panel = Color(0xFF0A111B);
const panel2 = Color(0xFF0D1622);
const line = Color(0xFF243142);
const gold = Color(0xFFE7AD2F);
const gold2 = Color(0xFFF5C84B);
const green = Color(0xFF27D86B);
const red = Color(0xFFFF4B4B);
const blue = Color(0xFF20A7FF);

class Candle { final double o, h, l, c, v; const Candle(this.o, this.h, this.l, this.c, this.v); }
class Factor { final String name; final int score; const Factor(this.name, this.score); }
class Analysis {
  final String regime, direction, decision, psychology, pattern;
  final int favor, buyer, seller;
  final double rsi, ema20, ema50, ema200, atr, support1, support2, resistance1, resistance2, fairValue, current;
  final List<Factor> factors;
  const Analysis({required this.regime, required this.direction, required this.decision, required this.psychology, required this.pattern, required this.favor, required this.buyer, required this.seller, required this.rsi, required this.ema20, required this.ema50, required this.ema200, required this.atr, required this.support1, required this.support2, required this.resistance1, required this.resistance2, required this.fairValue, required this.current, required this.factors});
}

class IntegratedApp extends StatelessWidget {
  const IntegratedApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Master Trading Engine', theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg, colorScheme: const ColorScheme.dark(primary: gold, surface: panel)), home: const Home());
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }
class _HomeState extends State<Home> {
  final symbol = TextEditingController(text: 'BTCUSDT');
  String tf = '15m', error = ''; bool loading = false, live = false; Timer? timer; List<Candle> candles = []; Analysis? a; int page = 0;
  final pages = const ['Dashboard','Live Market','AI Analysis','AI Chat','AI Strategy','Backtest','Paper Trading','Portfolio','Trade Journal','Alerts','Reports','Settings'];
  @override void dispose() { timer?.cancel(); symbol.dispose(); super.dispose(); }
  Future<void> load() async {
    if (loading) return; setState(() => loading = true);
    try {
      final s = symbol.text.trim().toUpperCase();
      final uri = Uri.parse('https://api.binance.com/api/v3/klines?symbol=$s&interval=$tf&limit=200');
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final raw = jsonDecode(r.body) as List;
      final d = raw.map((x) => Candle(double.parse(x[1]), double.parse(x[2]), double.parse(x[3]), double.parse(x[4]), double.parse(x[5]))).toList();
      if (!mounted) return; setState(() { candles = d; a = analyze(d); error = ''; });
    } catch (e) { if (mounted) setState(() => error = 'Live feed error: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void setLive(bool v) { timer?.cancel(); setState(() => live = v); if (v) { load(); timer = Timer.periodic(const Duration(seconds: 15), (_) => load()); } }
  @override Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(body: Row(children: [if (wide) _sidebar(), Expanded(child: SafeArea(child: _content(wide)))]));
  }
  Widget _sidebar() => Container(width: 185, decoration: const BoxDecoration(color: Color(0xFF070D15), border: Border(right: BorderSide(color: Color(0xFF1D2938)))), child: Column(children: [const SizedBox(height: 18), Row(children: [const SizedBox(width: 12), _logo(), const SizedBox(width: 9), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MASTER TRADING', style: TextStyle(color: gold2, fontWeight: FontWeight.w800, fontSize: 13)), Text('LIVE MARKET INTELLIGENCE', style: TextStyle(fontSize: 7, color: Colors.white))]))]), const SizedBox(height: 22), Expanded(child: ListView.builder(itemCount: pages.length, itemBuilder: (_, i) => _nav(i, pages[i]))), const Padding(padding: EdgeInsets.all(12), child: Row(children: [Icon(Icons.circle, color: green, size: 8), SizedBox(width: 6), Text('CONNECTION LIVE', style: TextStyle(fontSize: 9, color: Colors.white70))]))]);
  Widget _logo() => Container(width: 38, height: 38, decoration: BoxDecoration(border: Border.all(color: gold, width: 2), shape: BoxShape.circle), alignment: Alignment.center, child: const Text('M', style: TextStyle(color: gold2, fontWeight: FontWeight.w900)));
  Widget _nav(int i, String text) => InkWell(onTap: () => setState(() => page = i), child: Container(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: page == i ? const Color(0xFF211A0D) : Colors.transparent, border: Border.all(color: page == i ? const Color(0xFF72551B) : Colors.transparent), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: page == i ? gold2 : Colors.white60, fontSize: 11))));
  Widget _content(bool wide) {
    if (page != 0) return Center(child: Text('${pages[page]} module', style: const TextStyle(color: gold2, fontSize: 22, fontWeight: FontWeight.bold)));
    final x = a;
    return RefreshIndicator(onRefresh: load, color: gold2, child: ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('MASTER TRADING ENGINE', style: TextStyle(color: gold2, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: 1)), SizedBox(height: 2), Text('LIVE MARKET INTELLIGENCE', style: TextStyle(color: Colors.white70, fontSize: 10))])), _marketControls()]),
      const SizedBox(height: 9), _topCards(x),
      const SizedBox(height: 9),
      if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _mainColumn(x)), const SizedBox(width: 9), SizedBox(width: 340, child: _rightColumn(x))]) else ...[_mainColumn(x), const SizedBox(height: 9), _rightColumn(x)],
      const SizedBox(height: 9), _quickActions(), const SizedBox(height: 9), _bottomCards(x)
    ]));
  }
  Widget _marketControls() => Card(color: panel, child: Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 105, child: TextField(controller: symbol, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(isDense: true, labelText: 'Market', border: OutlineInputBorder()))), const SizedBox(width: 6), DropdownButton<String>(value: tf, items: const ['1m','3m','5m','15m','1h','4h'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 11)))).toList(), onChanged: (v) { if (v != null) setState(() => tf = v); }), const SizedBox(width: 5), IconButton(onPressed: loading ? null : load, icon: Icon(loading ? Icons.hourglass_top : Icons.refresh, color: gold2)), FilterChip(selected: live, onSelected: setLive, label: Text(live ? 'LIVE' : 'LIVE OFF', style: const TextStyle(fontSize: 9)))]));
  Widget _topCards(Analysis? x) => LayoutBuilder(builder: (_, c) { final n = c.maxWidth >= 800 ? 5 : 2; return GridView.count(crossAxisCount: n, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5, children: [_card('MARKET', x == null ? '--' : _price(x.current), x == null ? 'Press refresh' : '${x.direction} bias', x == null ? Colors.white70 : (x.direction == 'SHORT' ? red : green)), _card('MARKET REGIME', x?.regime ?? '--', x == null ? '' : 'Strength ${x.favor}%', x == null ? Colors.white70 : green), _card('TREND DIRECTION', x?.direction ?? '--', x == null ? '' : 'EMA 20 / 50 / 200', x == null ? Colors.white70 : x.direction == 'SHORT' ? red : green), _card('VOLATILITY', x == null ? '--' : _price(x.atr), x == null ? '' : 'ATR (14)', gold2), _card('TIMEFRAME', tf.toUpperCase(), 'Live candles', gold2)]); });
  Widget _card(String label, String value, String sub, Color color) => Card(color: panel2, child: Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)), const SizedBox(height: 6), Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)), if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 9))])));
  Widget _mainColumn(Analysis? x) => Column(children: [_chart(), const SizedBox(height: 9), if (x != null) LayoutBuilder(builder: (_, c) { final cols = c.maxWidth >= 720 ? 2 : 1; return GridView.count(crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: cols == 2 ? 1.55 : 2.1, children: [_tradeSetup(x), _marketFactors(x), _copilot(x)]; }), else _empty()]);
  Widget _chart() => Card(color: panel, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [Row(children: [Text('${symbol.text.toUpperCase()} · ${tf.toUpperCase()} · BINANCE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), const Spacer(), Text('${candles.length} candles', style: const TextStyle(fontSize: 9, color: Colors.white54))]), const SizedBox(height: 7), SizedBox(height: 360, child: candles.isEmpty ? const Center(child: Text('Analyze market to load live chart', style: TextStyle(color: Colors.white54))) : CustomPaint(painter: CandlePainter(candles, a)))])));
  Widget _tradeSetup(Analysis x) { final long = x.direction != 'SHORT'; final entry = x.current; final sl = long ? entry - x.atr * 1.2 : entry + x.atr * 1.2; final tp1 = long ? entry + x.atr * 2.0 : entry - x.atr * 2.0; final tp2 = long ? entry + x.atr * 3.0 : entry - x.atr * 3.0; return _panel('TRADE SETUP', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.direction == 'NEUTRAL' ? 'WAIT' : x.direction == 'LONG' ? 'BUY ↗' : 'SELL ↘', style: TextStyle(color: x.direction == 'SHORT' ? red : green, fontSize: 24, fontWeight: FontWeight.bold)), _row('Entry', _price(entry)), _row('Stop Loss', _price(sl), x.direction == 'SHORT' ? red : red), _row('Take Profit 1', _price(tp1), green), _row('Take Profit 2', _price(tp2), green), _row('Risk / Reward', '1 : 2.00'), _row('Confidence', '${x.favor}%') ])); }
  Widget _marketFactors(Analysis x) => _panel('MARKET FACTORS', Column(children: x.factors.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 105, child: Text(f.name, style: const TextStyle(fontSize: 9))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: f.score / 100, minHeight: 5, backgroundColor: const Color(0xFF283241), color: f.score >= 70 ? green : gold))), const SizedBox(width: 7), Text('${f.score}%', style: const TextStyle(fontSize: 9))]))).toList()));
  Widget _copilot(Analysis x) => _panel('AI MARKET COPILOT', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Why is this setup favorable?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 7), Text(x.psychology, style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.5)), const SizedBox(height: 8), Text('RSI ${x.rsi.toStringAsFixed(1)} • Fair Value ${_price(x.fairValue)} • Pattern ${x.pattern}', style: const TextStyle(color: Colors.white54, fontSize: 9))]));
  Widget _rightColumn(Analysis? x) => Column(children: [if (x != null) ...[_fairValue(x), _favorability(x), _levels(x), _pattern(x), _sentiment(x)] else _empty()]);
  Widget _fairValue(Analysis x) { final delta = x.current - x.fairValue; return _panel('FAIR VALUE ANALYSIS', Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fair Value\n${_price(x.fairValue)}'), Text('Current Price\n${_price(x.current)}', textAlign: TextAlign.right)]), const SizedBox(height: 12), Stack(children: [Container(height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [green, gold, Color(0xFFD93D3D)]))), Positioned(left: (MediaQuery.sizeOf(context).width * .76).clamp(5, 300), top: -4, child: Container(width: 2, height: 16, color: Colors.white))]), const SizedBox(height: 7), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Undervalued', style: TextStyle(color: green, fontSize: 8)), Text('Fair Value', style: TextStyle(color: gold2, fontSize: 8)), Text('Overvalued', style: TextStyle(color: red, fontSize: 8))]), const SizedBox(height: 6), Text('${delta >= 0 ? '+' : ''}${_price(delta)} from fair value', style: TextStyle(color: delta >= 0 ? red : green, fontSize: 10, fontWeight: FontWeight.bold))])); }
  Widget _favorability(Analysis x) => _panel('FAVORABILITY SCORE (12 FACTORS)', Row(children: [_ring(x.favor), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.favor >= 75 ? 'HIGH' : 'MODERATE', style: TextStyle(color: x.favor >= 75 ? green : gold2, fontSize: 18, fontWeight: FontWeight.bold)), const Text('Probability / setup quality', style: TextStyle(color: Colors.white60, fontSize: 9))]) ]));
  Widget _ring(int v) => SizedBox(width: 82, height: 82, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: v / 100, strokeWidth: 7, color: gold2, backgroundColor: const Color(0xFF303944)), Text('$v', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))]));
  Widget _levels(Analysis x) => _panel('KEY LEVELS', Column(children: [_row('Resistance 2', _price(x.resistance2), red), _row('Resistance 1', _price(x.resistance1), red), _row('Current Price', _price(x.current), green), _row('Support 1', _price(x.support1), blue), _row('Support 2', _price(x.support2), blue)]));
  Widget _pattern(Analysis x) => _panel('CANDLESTICK PATTERN', Row(children: [const Text('▮▮', style: TextStyle(fontSize: 32, color: gold2)), const SizedBox(width: 14), Text(x.pattern, style: const TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 12))]));
  Widget _sentiment(Analysis x) => _panel('MARKET SENTIMENT', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('BUYERS ${x.buyer}%  •  SELLERS ${x.seller}%', style: TextStyle(color: x.buyer >= 50 ? green : red, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 6), LinearProgressIndicator(value: x.buyer / 100, minHeight: 7, color: green, backgroundColor: red)]));
  Widget _quickActions() => LayoutBuilder(builder: (_, c) { final n = c.maxWidth >= 900 ? 6 : 3; final labels = ['AI Trade','AI Chat','AI Strategy','Backtest','Paper Trading','Alerts']; return GridView.count(crossAxisCount: n, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5, children: labels.map((s) => InkWell(onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$s opened'))), child: Card(color: panel2, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s, style: const TextStyle(color: gold2, fontWeight: FontWeight.bold, fontSize: 10)), const SizedBox(height: 2), const Text('Open module', style: TextStyle(color: Colors.white54, fontSize: 8))]))))).toList()); });
  Widget _bottomCards(Analysis? x) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _panel('RECENT ALERTS', Column(children: [_alert('${symbol.text.toUpperCase()}', 'Market analysis updated'), _alert('REGIME', x?.regime ?? 'Waiting for data'), _alert('TIMEFRAME', tf.toUpperCase())]))), const SizedBox(width: 9), Expanded(child: _panel('PERFORMANCE (PAPER TRADING)', const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('Trades\n25'), Text('P&L\n+2,450.75'), Text('Win Rate\n72.2%'), Text('Drawdown\n4.21%')])))]);
  Widget _alert(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text(a, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)), const Spacer(), Text(b, style: const TextStyle(color: Colors.white60, fontSize: 9))]));
  Widget _panel(String title, Widget child) => Card(color: panel, child: Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: gold2, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: .5)), const SizedBox(height: 9), child])));
  Widget _row(String k, String v, [Color? c]) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text(k, style: const TextStyle(color: Colors.white60, fontSize: 9)), const Spacer(), Text(v, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))]));
  Widget _empty() => _panel('MARKET INTELLIGENCE', const Center(child: Padding(padding: EdgeInsets.all(18), child: Text('Press refresh to load live market data.', style: TextStyle(color: Colors.white54)))));
  String _price(double v) => v.abs() >= 1000 ? v.toStringAsFixed(2) : v.toStringAsFixed(4);
}

Analysis analyze(List<Candle> c) {
  final cl = c.map((x) => x.c).toList();
  double ema(int n) { var e = cl.first; final k = 2 / (n + 1); for (final p in cl.skip(1)) e = p * k + e * (1 - k); return e; }
  double rsi() { var g = 0.0, l = 0.0; final n = math.min(14, cl.length - 1); for (var i = cl.length - n; i < cl.length; i++) { final d = cl[i] - cl[i - 1]; if (d >= 0) g += d; else l -= d; } return l == 0 ? 100 : 100 - 100 / (1 + g / l); }
  double atr() { var s = 0.0; final n = math.min(14, c.length - 1); for (var i = c.length - n; i < c.length; i++) s += math.max(c[i].h - c[i].l, math.max((c[i].h - c[i - 1].c).abs(), (c[i].l - c[i - 1].c).abs())); return s / n; }
  final e20 = ema(20), e50 = ema(50), e200 = ema(200), rr = rsi(), at = atr(), last = cl.last;
  final start = math.max(0, c.length - 21); final range = c.sublist(start); final hi = range.map((x) => x.h).reduce(math.max), lo = range.map((x) => x.l).reduce(math.min);
  final bull = e20 > e50 && e50 > e200 && last > e20 && rr >= 52, bear = e20 < e50 && e50 < e200 && last < e20 && rr <= 48;
  final upBreak = last > hi - at * .15, downBreak = last < lo + at * .15; final direction = bull || upBreak ? 'LONG' : bear || downBreak ? 'SHORT' : 'NEUTRAL';
  final regime = (bull || bear) ? 'TREND' : (upBreak || downBreak) ? 'BREAKOUT' : 'RANGE';
  final avg = range.map((x) => x.v).reduce((a, b) => a + b) / range.length; final vr = c.last.v / avg;
  final values = <int>[bull || bear ? 90 : 55, regime == 'BREAKOUT' ? 90 : 65, direction == 'NEUTRAL' ? 55 : 82, rr >= 55 && rr <= 70 ? 86 : 65, vr >= 1.25 ? 90 : 65, (last > e20 ? 82 : 55), ((last - lo) / math.max(1, hi - lo) * 100).round().clamp(0, 100), (last >= e50 ? 80 : 55), c.last.c >= c.last.o ? 78 : 60, direction == 'NEUTRAL' ? 55 : 84, vr >= .8 ? 75 : 55, 78];
  final names = ['Trend','Market Regime','Structure','Momentum','Volume','EMA Alignment','Range Position','Fair Value','Pattern','Risk/Reward','Liquidity','Session']; final factors = List.generate(12, (i) => Factor(names[i], values[i])); final favor = (values.reduce((a, b) => a + b) / values.length).round();
  final buyer = (50 + (bull ? 20 : bear ? -20 : 0) + (rr - 50) * .5 + (vr > 1.25 ? 10 : 0)).round().clamp(5, 95); final fair = (e20 + e50 + e200) / 3;
  final pattern = c.last.c > c.last.o ? (c.last.c > c.last.o * 1.006 ? 'Bullish Engulfing' : 'Bullish Candle') : (c.last.o > c.last.c * 1.006 ? 'Bearish Engulfing' : 'Bearish Candle');
  final psychology = direction == 'LONG' ? 'Buyers have structural control. Momentum is positive, but wait for clean confirmation near key levels.' : direction == 'SHORT' ? 'Sellers have structural control. Downside momentum is visible; confirmation remains important.' : 'Buyer and seller evidence is mixed. Avoid forcing a directional setup until structure improves.';
  final decision = favor >= 80 ? 'STRONG SETUP' : favor >= 68 ? 'WATCH' : 'NO TRADE';
  return Analysis(regime: regime, direction: direction, decision: decision, psychology: psychology, pattern: pattern, favor: favor, buyer: buyer, seller: 100 - buyer, rsi: rr, ema20: e20, ema50: e50, ema200: e200, atr: at, support1: lo, support2: lo - at, resistance1: hi, resistance2: hi + at, fairValue: fair, current: last, factors: factors);
}

class CandlePainter extends CustomPainter {
  final List<Candle> data; final Analysis? analysis; CandlePainter(this.data, this.analysis);
  @override void paint(Canvas canvas, Size size) {
    final n = math.min(90, data.length); final d = data.sublist(data.length - n); final hi = d.map((x) => x.h).reduce(math.max), lo = d.map((x) => x.l).reduce(math.min); final range = math.max(1, hi - lo); final w = size.width / n; final grid = Paint()..color = const Color(0xFF132231)..strokeWidth = 1;
    for (var y = 20.0; y < size.height; y += 45) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    for (var i = 0; i < n; i++) { final k = d[i], x = i * w + w / 2; double y(double p) => size.height - (p - lo) / range * (size.height - 25) - 10; final p = Paint()..color = k.c >= k.o ? green : red..strokeWidth = 1; canvas.drawLine(Offset(x, y(k.h)), Offset(x, y(k.l)), p); final top = y(math.max(k.o, k.c)), bottom = y(math.min(k.o, k.c)); canvas.drawRect(Rect.fromLTWH(x - w * .3, top, w * .6, math.max(2, bottom - top)), p);
    }
    if (analysis != null) { final p = Paint()..color = gold2..strokeWidth = 1.3; double y(double price) => size.height - (price - lo) / range * (size.height - 25) - 10; canvas.drawLine(Offset(0, y(analysis!.fairValue)), Offset(size.width, y(analysis!.fairValue)), p); }
  }
  @override bool shouldRepaint(covariant CandlePainter oldDelegate) => oldDelegate.data != data || oldDelegate.analysis != analysis;
}
