import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const bg = Color(0xFF050A11);
const panel = Color(0xFF0A111B);
const gold = Color(0xFFE7AD2F);
const green = Color(0xFF27D86B);
const red = Color(0xFFFF4B4B);
const blue = Color(0xFF20A7FF);

class Candle {
  final double o;
  final double h;
  final double l;
  final double c;
  final double v;

  const Candle(this.o, this.h, this.l, this.c, this.v);
}

class Analysis {
  final String regime;
  final String direction;
  final String psychology;
  final int score;
  final int buyer;
  final int seller;
  final double rsi;
  final double ema20;
  final double ema50;
  final double ema200;
  final double atr;
  final double support;
  final double resistance;
  final double fair;
  final bool trend;
  final bool breakout;

  const Analysis({
    required this.regime,
    required this.direction,
    required this.psychology,
    required this.score,
    required this.buyer,
    required this.seller,
    required this.rsi,
    required this.ema20,
    required this.ema50,
    required this.ema200,
    required this.atr,
    required this.support,
    required this.resistance,
    required this.fair,
    required this.trend,
    required this.breakout,
  });
}

class IntegratedApp extends StatefulWidget {
  const IntegratedApp({super.key});

  @override
  State<IntegratedApp> createState() => _IntegratedAppState();
}

class _IntegratedAppState extends State<IntegratedApp> {
  final TextEditingController symbol = TextEditingController(text: 'BTCUSDT');
  final List<String> nav = const [
    'Dashboard',
    'Live Market',
    'AI Analysis',
    'AI Chat',
    'AI Strategy',
    'Backtest',
    'Paper Trading',
    'Portfolio',
    'Trade Journal',
    'Alerts',
    'Reports',
    'Settings',
  ];

  String interval = '15m';
  String status = 'ENGINE SYNC';
  String error = '';
  bool live = true;
  bool loading = false;
  Timer? timer;
  List<Candle> candles = const [];
  Analysis? analysis;
  int page = 0;

  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (live) refresh();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    symbol.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (loading) return;
    if (!mounted) return;

    setState(() => loading = true);
    try {
      final s = symbol.text.trim().toUpperCase();
      if (s.isEmpty) throw Exception('Market symbol is empty');

      final uri = Uri.https('api.binance.com', '/api/v3/klines', {
        'symbol': s,
        'interval': interval,
        'limit': '200',
      });
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('Invalid market response');

      final parsed = <Candle>[];
      for (final row in decoded) {
        if (row is! List || row.length < 6) continue;
        parsed.add(Candle(
          double.parse(row[1].toString()),
          double.parse(row[2].toString()),
          double.parse(row[3].toString()),
          double.parse(row[4].toString()),
          double.parse(row[5].toString()),
        ));
      }

      if (parsed.length < 3) throw Exception('Not enough market candles');
      if (!mounted) return;

      setState(() {
        candles = parsed;
        analysis = analyze(parsed);
        status = 'ENGINE LIVE';
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        status = 'FEED ERROR';
        error = 'Market feed error: $e';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void setLive(bool value) {
    setState(() => live = value);
    if (value) refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Master Trading Engine',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: gold),
      ),
      home: Scaffold(
        body: Row(
          children: [
            if (MediaQuery.sizeOf(context).width >= 900) _sidebar(),
            Expanded(child: SafeArea(child: _content())),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 190,
      color: const Color(0xFF070D15),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'MASTER TRADING',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold),
          ),
          const Text(
            'LIVE MARKET INTELLIGENCE',
            style: TextStyle(fontSize: 8, color: Colors.white60),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              itemCount: nav.length,
              itemBuilder: (_, i) {
                return ListTile(
                  dense: true,
                  selected: i == page,
                  selectedTileColor: const Color(0xFF211A0D),
                  title: Text(
                    nav[i],
                    style: TextStyle(
                      color: i == page ? gold : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () => setState(() => page = i),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.circle, color: green, size: 8),
                SizedBox(width: 6),
                Text(
                  'CONNECTION LIVE',
                  style: TextStyle(fontSize: 9, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (page != 0) {
      return Center(
        child: Text(
          '${nav[page]} module',
          style: const TextStyle(
            color: gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final current = analysis;
    return RefreshIndicator(
      onRefresh: refresh,
      color: gold,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _header(),
          if (error.isNotEmpty) _errorCard(),
          const SizedBox(height: 10),
          _summary(current),
          const SizedBox(height: 10),
          _chart(),
          const SizedBox(height: 10),
          if (current != null)
            _analysisGrid(current)
          else
            _panel(
              'TRADE ENGINE',
              const Text(
                'Waiting for connected market data...',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          const SizedBox(height: 10),
          _actions(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MASTER TRADING ENGINE',
                style: TextStyle(
                  color: gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'LIVE MARKET INTELLIGENCE · ENGINE CONNECTED',
                style: TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 105,
          child: TextField(
            controller: symbol,
            onSubmitted: (_) => refresh(),
            style: const TextStyle(fontSize: 10),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Market',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        DropdownButton<String>(
          value: interval,
          items: const ['1m', '5m', '15m', '1h', '4h', '1d']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => interval = value);
            refresh();
          },
        ),
        IconButton(
          onPressed: loading ? null : refresh,
          icon: const Icon(Icons.refresh, color: gold),
        ),
        FilterChip(
          selected: live,
          onSelected: setLive,
          label: Text(
            live ? '● LIVE' : '○ LIVE OFF',
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _errorCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning, color: red),
        title: const Text('Market feed error'),
        subtitle: Text(error),
      ),
    );
  }

  Widget _summary(Analysis? a) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 800 ? 5 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.25,
          children: [
            _card('MARKET', a == null ? '--' : fmt(a.ema20), 'BTC/USDT', gold),
            _card('REGIME', a?.regime ?? '--', 'Engine detection', green),
            _card(
              'DIRECTION',
              a?.direction ?? '--',
              a == null ? 'Waiting' : '${a.score}% confidence',
              a?.direction == 'SHORT' ? red : green,
            ),
            _card(
              'VOLATILITY',
              a == null
                  ? '--'
                  : '${(a.atr / math.max(1.0, a.ema20.abs()) * 100).toStringAsFixed(2)}%',
              'ATR (14)',
              gold,
            ),
            _card('TIMEFRAME', interval.toUpperCase(), status, gold),
          ],
        );
      },
    );
  }

  Widget _card(String title, String value, String subtitle, Color color) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 9)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chart() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${symbol.text.toUpperCase()} · ${interval.toUpperCase()} · BINANCE',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: status == 'ENGINE LIVE' ? green : red,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 330,
              child: candles.isEmpty
                  ? const Center(child: Text('Loading connected market feed...'))
                  : CustomPaint(
                      painter: CandlePainter(candles),
                      child: const SizedBox.expand(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisGrid(Analysis a) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.65,
          children: [
            _setup(a),
            _factors(a),
            _fair(a),
            _levels(a),
            _sentiment(a),
            _copilot(a),
          ],
        );
      },
    );
  }

  Widget _setup(Analysis a) {
    final action = a.direction == 'NEUTRAL'
        ? 'WAIT'
        : a.direction == 'LONG'
            ? 'BUY ↗'
            : 'SELL ↘';
    final stop = a.direction == 'LONG'
        ? a.ema20 - a.atr * 1.2
        : a.ema20 + a.atr * 1.2;
    final target = a.direction == 'LONG'
        ? a.ema20 + a.atr * 2
        : a.ema20 - a.atr * 2;

    return _panel(
      'TRADE SETUP',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action,
            style: TextStyle(
              color: a.direction == 'SHORT' ? red : green,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          _kv('Reference', fmt(a.ema20)),
          _kv('Stop reference', fmt(stop), red),
          _kv('Target reference', fmt(target), green),
          _kv('Confidence', '${a.score}%', green),
        ],
      ),
    );
  }

  Widget _factors(Analysis a) {
    const names = [
      'Trend',
      'Regime',
      'Structure',
      'Momentum',
      'Volume',
      'Volatility',
      'Support/Resistance',
      'Fair Value',
      'Pattern',
      'Risk/Reward',
      'Liquidity',
      'Session',
    ];

    final values = <int>[
      a.trend ? 88 : 55,
      a.breakout ? 90 : 75,
      82,
      a.rsi.round().clamp(0, 100),
      75,
      70,
      85,
      80,
      70,
      78,
      75,
      80,
    ];

    return _panel(
      'MARKET FACTORS · 12',
      Column(
        children: List.generate(names.length, (i) {
          final value = values[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 105,
                  child: Text(names[i], style: const TextStyle(fontSize: 8)),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF283241),
                    color: value >= 70 ? green : gold,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$value%', style: const TextStyle(fontSize: 8)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _fair(Analysis a) {
    final position = ((a.ema20 - a.support) /
            math.max(1.0, a.resistance - a.support))
        .clamp(0.0, 1.0)
        .toDouble();

    return _panel(
      'FAIR VALUE ANALYSIS',
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fair Value\n${fmt(a.fair)}'),
              Text('Reference\n${fmt(a.ema20)}', textAlign: TextAlign.right),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: position,
            minHeight: 8,
            color: gold,
            backgroundColor: const Color(0xFF303944),
          ),
          const SizedBox(height: 8),
          Text(
            a.fair <= a.ema20
                ? 'Near / below fair-value reference'
                : 'Above fair-value reference',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _levels(Analysis a) {
    return _panel(
      'KEY LEVELS',
      Column(
        children: [
          _kv('Resistance', fmt(a.resistance), red),
          _kv('Fair Value', fmt(a.fair), gold),
          _kv('Support', fmt(a.support), blue),
          _kv('ATR', fmt(a.atr), gold),
        ],
      ),
    );
  }

  Widget _sentiment(Analysis a) {
    return _panel(
      'MARKET SENTIMENT',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUYERS ${a.buyer}% · SELLERS ${a.seller}%',
            style: TextStyle(
              color: a.buyer >= 50 ? green : red,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: a.buyer / 100,
            minHeight: 7,
            color: green,
            backgroundColor: red,
          ),
          const SizedBox(height: 5),
          Text(
            a.buyer >= 55
                ? 'Bullish'
                : a.buyer <= 45
                    ? 'Bearish'
                    : 'Neutral',
            style: const TextStyle(color: Colors.white60, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _copilot(Analysis a) {
    return _panel(
      'AI MARKET COPILOT',
      Text(
        'Market regime: ${a.regime}. Direction: ${a.direction}. '
        'RSI ${a.rsi.toStringAsFixed(1)}, EMA20 ${fmt(a.ema20)}, '
        'EMA50 ${fmt(a.ema50)}, EMA200 ${fmt(a.ema200)}. '
        'This dashboard provides analysis and paper-trading information only.',
        style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.5),
      ),
    );
  }

  Widget _actions() {
    final actions = ['AI Trade', 'AI Chat', 'AI Strategy', 'Backtest', 'Paper Trading', 'Alerts'];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.3,
      children: actions
          .map(
            (label) => Card(
              color: panel,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: gold,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String fmt(double value) {
  return value.abs() >= 1000
      ? value.toStringAsFixed(2)
      : value.toStringAsFixed(4);
}

Analysis analyze(List<Candle> data) {
  if (data.length < 3) {
    return const Analysis(
      regime: 'WAITING',
      direction: 'NEUTRAL',
      psychology: 'Waiting for enough market data.',
      score: 0,
      buyer: 50,
      seller: 50,
      rsi: 50,
      ema20: 0,
      ema50: 0,
      ema200: 0,
      atr: 0,
      support: 0,
      resistance: 0,
      fair: 0,
      trend: false,
      breakout: false,
    );
  }

  final close = data.map((x) => x.c).toList();
  final lookback = math.min(21, data.length);
  final start = data.length - lookback;

  double ema(int period) {
    var value = close.first;
    final k = 2.0 / (period + 1.0);
    for (final price in close.skip(1)) {
      value = price * k + value * (1.0 - k);
    }
    return value;
  }

  double minValue(Iterable<double> values) {
    var result = double.infinity;
    for (final value in values) {
      if (value < result) result = value;
    }
    return result;
  }

  double maxValue(Iterable<double> values) {
    var result = -double.infinity;
    for (final value in values) {
      if (value > result) result = value;
    }
    return result;
  }

  final e20 = ema(20);
  final e50 = ema(50);
  final e200 = ema(200);
  final period = math.min(14, close.length - 1);

  var gain = 0.0;
  var loss = 0.0;
  var trueRange = 0.0;
  final rsiStart = close.length - period;

  for (var i = rsiStart; i < close.length; i++) {
    final change = close[i] - close[i - 1];
    if (change >= 0) {
      gain += change;
    } else {
      loss -= change;
    }
    trueRange += math.max(
      data[i].h - data[i].l,
      math.max(
        (data[i].h - data[i - 1].c).abs(),
        (data[i].l - data[i - 1].c).abs(),
      ),
    );
  }

  final rsi = loss == 0 ? 100.0 : 100.0 - (100.0 / (1.0 + gain / loss));
  final atr = trueRange / period;
  final support = minValue(data.sublist(start).map((x) => x.l));
  final resistance = maxValue(data.sublist(start).map((x) => x.h));
  final last = close.last;

  final previousStart = math.max(0, data.length - lookback - 1);
  final previousEnd = data.length - 1;
  final previousHigh = maxValue(
    data.sublist(previousStart, previousEnd).map((x) => x.h),
  );
  final previousLow = minValue(
    data.sublist(previousStart, previousEnd).map((x) => x.l),
  );

  final bull = e20 > e50 && e50 > e200 && last > e20 && rsi >= 52;
  final bear = e20 < e50 && e50 < e200 && last < e20 && rsi <= 48;
  final breakoutUp = last > previousHigh;
  final breakoutDown = last < previousLow;
  final breakout = breakoutUp || breakoutDown;

  final direction = bull || breakoutUp
      ? 'LONG'
      : bear || breakoutDown
          ? 'SHORT'
          : 'NEUTRAL';
  final trend = bull || bear;
  final regime = breakout
      ? 'BREAKOUT'
      : trend
          ? 'TREND'
          : 'RANGE';

  var score = 35;
  if (trend) score += 20;
  if (breakout) score += 20;
  if (rsi >= 55 || rsi <= 45) score += 10;
  if (direction == 'NEUTRAL') score = math.min(score, 59);
  score = math.min(score, 100);

  final buyerRaw = 50 +
      (rsi - 50) * 1.4 +
      (bull ? 18 : 0) +
      (breakoutUp ? 12 : 0) -
      (breakoutDown ? 12 : 0);
  final buyer = buyerRaw.round().clamp(5, 95);
  final psychology = direction == 'LONG'
      ? 'Buyers have structural control.'
      : direction == 'SHORT'
          ? 'Sellers have structural control.'
          : 'No clean participant edge.';

  return Analysis(
    regime: regime,
    direction: direction,
    psychology: psychology,
    score: score,
    buyer: buyer,
    seller: 100 - buyer,
    rsi: rsi,
    ema20: e20,
    ema50: e50,
    ema200: e200,
    atr: atr,
    support: support,
    resistance: resistance,
    fair: e20,
    trend: trend,
    breakout: breakout,
  );
}

class CandlePainter extends CustomPainter {
  final List<Candle> data;

  CandlePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) return;

    final count = math.min(80, data.length);
    final visible = data.sublist(data.length - count);
    var high = -double.infinity;
    var low = double.infinity;

    for (final candle in visible) {
      high = math.max(high, candle.h);
      low = math.min(low, candle.l);
    }

    final range = high == low ? 1.0 : high - low;
    final width = size.width / count;
    final paint = Paint()..strokeWidth = 1.2;

    double y(double value) {
      return size.height - ((value - low) / range * size.height);
    }

    for (var i = 0; i < count; i++) {
      final candle = visible[i];
      final x = i * width + width / 2;
      paint.color = candle.c >= candle.o ? Colors.greenAccent : Colors.redAccent;

      canvas.drawLine(
        Offset(x, y(candle.h)),
        Offset(x, y(candle.l)),
        paint,
      );

      final top = y(math.max(candle.o, candle.c));
      final bottom = y(math.min(candle.o, candle.c));
      canvas.drawRect(
        Rect.fromLTWH(
          x - width * 0.3,
          top,
          width * 0.6,
          math.max(1.0, bottom - top),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
