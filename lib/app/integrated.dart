import 'dart:async';
import 'package:flutter/material.dart';
import 'live_intelligence.dart';
import 'fair_value.dart';
import 'trade_favorability.dart';
import 'risk_engine.dart';
import 'master_decision_engine.dart';
import 'market_data_provider.dart';

class Candle {
  final double o, h, l, c, v;
  const Candle(this.o, this.h, this.l, this.c, this.v);
}

class IntegratedApp extends StatelessWidget {
  const IntegratedApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Master Trading Engine',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.amber,
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final symbol = TextEditingController(text: 'NIFTY 50');
  String tf = '1h';
  String error = '';
  String source = '';
  String resolved = '';
  bool loading = false;
  Timer? timer;
  List<Candle> candles = [];
  IndicatorSnapshot? indicators;
  LiveSignal? signal;
  FairValueResult? fair;
  RiskPlan? risk;
  TradeFavorabilityResult? favor;
  MasterDecision? master;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !loading) load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    symbol.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final market = await const MarketDataProvider().fetch(
        inputSymbol: symbol.text,
        timeframe: tf,
      );
      final data = market.candles
          .map((x) => Candle(x.open, x.high, x.low, x.close, x.volume))
          .toList();
      if (data.length < 30) throw Exception('30 se kam candles mili');

      final input = data.map((x) => LiveCandle(x.o, x.h, x.l, x.c, x.v)).toList();
      final li = const LiveMarketIntelligence();
      final ind = li.calculate(input);
      final sig = li.analyze(input);
      final fv = const FairValueEngine().calculate(
        current: data.last.c,
        ema20: ind.ema20,
        ema50: ind.ema50,
        ema200: ind.ema200,
        support: ind.support,
        resistance: ind.resistance,
        rsi: ind.rsi14,
        atr: ind.atr14,
      );
      final rp = const RiskEngine().build(
        direction: sig.direction,
        price: data.last.c,
        atr: ind.atr14,
        support: ind.support,
        resistance: ind.resistance,
        fairValue: fv.fairValue,
      );
      final tfv = const TradeFavorabilityEngine().calculate(
        direction: sig.direction,
        bullishTrend: ind.bullishTrend,
        bearishTrend: ind.bearishTrend,
        price: data.last.c,
        ema20: ind.ema20,
        ema50: ind.ema50,
        ema200: ind.ema200,
        rsi: ind.rsi14,
        volumeRatio: ind.volumeRatio,
        support: ind.support,
        resistance: ind.resistance,
        breakoutUp: sig.breakoutUp,
        breakoutDown: sig.breakoutDown,
        atr: ind.atr14,
        rr1: rp.rewardToTarget1,
      );
      final md = const MasterDecisionEngine().evaluate(
        direction: sig.direction,
        regime: sig.regime,
        price: data.last.c,
        atr: ind.atr14,
        rsi: ind.rsi14,
        volumeRatio: ind.volumeRatio,
        ema20: ind.ema20,
        ema50: ind.ema50,
        ema200: ind.ema200,
        breakoutUp: sig.breakoutUp,
        breakoutDown: sig.breakoutDown,
        risk: rp,
        capital: 100000,
        riskPercent: 1,
      );

      if (!mounted) return;
      setState(() {
        candles = data;
        indicators = ind;
        signal = sig;
        fair = fv;
        risk = rp;
        favor = tfv;
        master = md;
        resolved = market.resolvedSymbol;
        source = market.source;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Live data nahi mil raha: $e';
        candles = [];
        indicators = null;
        signal = null;
        fair = null;
        risk = null;
        favor = null;
        master = null;
        resolved = '';
        source = '';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[_controls()];
    if (error.isNotEmpty) {
      widgets.add(_section('⚠️ DATA STATUS', [error]));
    } else if (candles.isNotEmpty) {
      widgets.add(_section('🟢 LIVE DATA', [
        'Data source: $source',
        'Symbol: $resolved',
        'Timeframe: $tf',
        'Candles: ${candles.length}',
      ]));
    }
    if (candles.isNotEmpty) {
      widgets.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            height: 240,
            child: CustomPaint(painter: CandlePainter(candles)),
          ),
        ),
      ));
    }
    if (master != null) widgets.add(_masterCard());
    if (fair != null) widgets.add(_fairCard());
    if (favor != null) widgets.add(_favorCard());
    if (master != null) widgets.add(_strategyCard());
    if (risk != null) widgets.add(_riskCard());
    if (master != null) widgets.add(_positionCard());
    if (indicators != null) widgets.add(_technicalCard());
    widgets.add(const Card(
      child: ListTile(
        leading: Icon(Icons.shield),
        title: Text('SAFETY LOCK'),
        subtitle: Text('Sirf analysis/paper-trading. Koi live broker order place nahi hota.'),
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('MASTER TRADING ENGINE'),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8),
            child: Chip(label: Text('ANALYSIS ONLY')),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(10), children: widgets),
    );
  }

  Widget _controls() => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: symbol,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Symbol / Naam',
                    hintText: 'NIFTY 50 / BANKNIFTY / RELIANCE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: tf,
                items: const ['1m', '5m', '15m', '1h', '1d']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (x) {
                  if (x != null) {
                    setState(() {
                      tf = x;
                      error = '';
                    });
                    load();
                  }
                },
              ),
              IconButton(
                onPressed: loading ? null : load,
                tooltip: 'Refresh data',
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );

  Widget _masterCard() {
    final m = master!;
    final v = favor;
    return _section('🔥 MAIN RESULT', [
      m.decision,
      'Direction: ${m.direction}',
      'Confidence: ${m.confidence}%',
      'Market type: ${m.regime}',
      '🟢 Mere favour me: ${v?.inFavor ?? 0}   🟡 Neutral: ${v?.neutral ?? 0}   🔴 Against: ${v?.against ?? 0}',
    ]);
  }

  Widget _fairCard() {
    final f = fair!;
    return _section('⚖️ FAIR VALUE', [
      'Abhi ka price: ${f.currentPrice.toStringAsFixed(2)}',
      'Estimated fair price: ${f.fairValue.toStringAsFixed(2)}',
      'Fair price range: ${f.zoneLow.toStringAsFixed(2)} – ${f.zoneHigh.toStringAsFixed(2)}',
      'Fair price se difference: ${f.distancePercent.toStringAsFixed(2)}%',
      'Status: ${f.status}',
      'Kitna bharosa: ${f.confidence}%',
      ...f.factors.map((x) => '• $x'),
    ]);
  }

  Widget _favorCard() {
    final v = favor!;
    return _section('🔥 TRADE FAVORABILITY', [
      '${v.overall}% trade mere favour me',
      '${v.inFavor} strong • ${v.neutral} neutral • ${v.against} weak',
      ...v.factors.map((x) =>
          '${x.score >= 70 ? '🟢' : x.score >= 50 ? '🟡' : '🔴'} ${x.name}: ${x.score}% — ${x.detail}'),
    ]);
  }

  Widget _strategyCard() => _section(
        '🧠 STRATEGY CHECK',
        master!.strategies.map((x) => '${x.name}: ${x.score}% — ${x.detail}').toList(),
      );

  Widget _riskCard() {
    final r = risk!;
    return _section('🛡️ RISK / REWARD', [
      'Direction: ${r.direction}',
      'Entry: ${r.entry.toStringAsFixed(2)}',
      'Stop Loss: ${r.stopLoss.toStringAsFixed(2)}',
      'Target 1: ${r.target1.toStringAsFixed(2)} • R:R ${r.rewardToTarget1.toStringAsFixed(2)}',
      'Target 2: ${r.target2.toStringAsFixed(2)} • R:R ${r.rewardToTarget2.toStringAsFixed(2)}',
      'Ek unit ka risk: ${r.riskPerUnit.toStringAsFixed(2)}',
    ]);
  }

  Widget _positionCard() {
    final m = master!;
    return _section('📐 KITNI QUANTITY?', [
      'Example capital: ₹100000',
      'Risk budget: ${m.riskAmount.toStringAsFixed(2)}',
      'Calculated quantity: ${m.positionSize.toStringAsFixed(6)}',
    ]);
  }

  Widget _technicalCard() {
    final i = indicators!;
    return _section('📈 TECHNICAL CHECK', [
      'Market type: ${signal?.regime}',
      'Direction: ${signal?.direction}',
      'EMA20: ${i.ema20.toStringAsFixed(2)}',
      'EMA50: ${i.ema50.toStringAsFixed(2)}',
      'EMA200: ${i.ema200.toStringAsFixed(2)}',
      'RSI: ${i.rsi14.toStringAsFixed(1)}',
      'ATR: ${i.atr14.toStringAsFixed(2)}',
      'Volume: ${i.volumeRatio.toStringAsFixed(2)}x average',
      'Support: ${i.support.toStringAsFixed(2)}',
      'Resistance: ${i.resistance.toStringAsFixed(2)}',
    ]);
  }

  Widget _section(String title, List<String> lines) => Card(
        child: ExpansionTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(lines.join('\n\n')),
              ),
            ),
          ],
        ),
      );
}

class CandlePainter extends CustomPainter {
  final List<Candle> data;
  CandlePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final d = data.length > 80 ? data.sublist(data.length - 80) : data;
    final hi = d.map((x) => x.h).reduce((a, b) => a > b ? a : b);
    final lo = d.map((x) => x.l).reduce((a, b) => a < b ? a : b);
    final range = hi == lo ? 1.0 : hi - lo;
    final w = size.width / d.length;
    final p = Paint()..strokeWidth = 1;
    double y(double value) => size.height - (value - lo) / range * size.height;
    for (var n = 0; n < d.length; n++) {
      final k = d[n];
      final x = n * w + w / 2;
      p.color = k.c >= k.o ? Colors.greenAccent : Colors.redAccent;
      canvas.drawLine(Offset(x, y(k.h)), Offset(x, y(k.l)), p);
      canvas.drawRect(
        Rect.fromLTRB(
          x - w * .3,
          y(k.o > k.c ? k.o : k.c),
          x + w * .3,
          y(k.o < k.c ? k.o : k.c),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlePainter oldDelegate) => oldDelegate.data != data;
}
