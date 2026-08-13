import 'dart:math' as math;
import 'package:flutter/material.dart';

class MasterTradingEngineApp extends StatelessWidget {
  const MasterTradingEngineApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Master Trading Engine',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.amber),
        home: const Home(),
      );
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Master Trading Engine'),
            actions: const [Chip(avatar: Icon(Icons.lock, size: 16), label: Text('AUTO-TRADING LOCKED'))],
            bottom: const TabBar(tabs: [
              Tab(icon: Icon(Icons.science), text: 'Backtest'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Paper'),
              Tab(icon: Icon(Icons.security), text: 'Safety'),
            ]),
          ),
          body: const TabBarView(children: [BacktestPage(), PaperPage(), SafetyPage()]),
        ),
      );
}

class BacktestPage extends StatefulWidget {
  const BacktestPage({super.key});
  @override
  State<BacktestPage> createState() => _BacktestPageState();
}

class _BacktestPageState extends State<BacktestPage> {
  final prices = TextEditingController(text: '100\n101\n102\n101\n103\n104\n102\n105');
  final capital = TextEditingController(text: '100000');
  final qty = TextEditingController(text: '1');
  double finalCapital = 100000, maxDd = 0;
  int trades = 0, wins = 0;
  List<double> curve = [];

  void runBacktest() {
    final initial = double.tryParse(capital.text) ?? 0;
    final q = double.tryParse(qty.text) ?? 0;
    final p = prices.text.split(RegExp(r'[\n,]+')).map(double.tryParse).whereType<double>().where((x) => x > 0).toList();
    if (initial <= 0 || q <= 0 || p.length < 2) return;
    var cash = initial, peak = initial, dd = 0.0;
    double? entry;
    String? side;
    var w = 0;
    var n = 0;
    final c = <double>[];
    for (var i = 1; i < p.length; i++) {
      final price = p[i];
      final previous = p[i - 1];
      if (entry == null) {
        if (price > previous) { entry = price; side = 'LONG'; }
        else if (price < previous) { entry = price; side = 'SHORT'; }
      } else {
        final pnl = side == 'LONG' ? (price - entry!) * q : (entry! - price) * q;
        final stop = side == 'LONG' ? price <= entry! * .99 : price >= entry! * 1.01;
        final target = side == 'LONG' ? price >= entry! * 1.02 : price <= entry! * .98;
        final reversal = (side == 'LONG' && price < previous) || (side == 'SHORT' && price > previous);
        if (stop || target || reversal || i == p.length - 1) {
          cash += pnl; n++; if (pnl > 0) w++;
          entry = null; side = null;
        }
      }
      final unreal = entry == null ? 0 : (side == 'LONG' ? (price - entry!) * q : (entry! - price) * q);
      final equity = cash + unreal;
      peak = math.max(peak, equity); dd = math.max(dd, peak - equity); c.add(equity);
    }
    setState(() { finalCapital = cash; maxDd = dd; trades = n; wins = w; curve = c; });
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Historical Backtest', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Close prices: one per line or comma separated. Simulation only.'),
        const SizedBox(height: 12),
        TextField(controller: capital, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Capital', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: prices, minLines: 6, maxLines: 10, decoration: const InputDecoration(labelText: 'Historical close prices', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: runBacktest, icon: const Icon(Icons.play_arrow), label: const Text('RUN BACKTEST')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          metric('Initial', '₹${(double.tryParse(capital.text) ?? 0).toStringAsFixed(0)}'),
          metric('Final', '₹${finalCapital.toStringAsFixed(2)}'),
          metric('Net P&L', '₹${(finalCapital - (double.tryParse(capital.text) ?? 0)).toStringAsFixed(2)}'),
          metric('Trades', '$trades'),
          metric('Win Rate', trades == 0 ? '0.00%' : '${(wins / trades * 100).toStringAsFixed(2)}%'),
          metric('Max DD', '₹${maxDd.toStringAsFixed(2)}'),
        ]),
        if (curve.length > 1) Card(margin: const EdgeInsets.only(top: 12), child: SizedBox(height: 180, child: CustomPaint(painter: CurvePainter(curve)))),
      ]);
}

class PaperPage extends StatefulWidget {
  const PaperPage({super.key});
  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
  final price = TextEditingController(text: '100');
  bool running = false, killed = false;
  double cash = 100000, realized = 0;
  double? entryPrice;
  int trades = 0;
  String lastAction = 'Waiting for paper tick';

  void tick() {
    final p = double.tryParse(price.text);
    if (!running || killed || p == null || p <= 0) return;
    setState(() {
      if (entryPrice == null) {
        entryPrice = p;
        lastAction = 'OPEN LONG @ ${p.toStringAsFixed(2)}';
        return;
      }

      final entry = entryPrice!;
      final pnl = p - entry;
      final targetHit = p >= entry * 1.02;
      final stopHit = p <= entry * .99;

      if (targetHit || stopHit) {
        cash += pnl;
        realized += pnl;
        trades++;
        lastAction = targetHit
            ? 'TARGET HIT — CLOSED @ ${p.toStringAsFixed(2)} | P&L ₹${pnl.toStringAsFixed(2)}'
            : 'STOP HIT — CLOSED @ ${p.toStringAsFixed(2)} | P&L ₹${pnl.toStringAsFixed(2)}';
        entryPrice = null;
      } else {
        lastAction = 'POSITION HELD — LONG @ ${entry.toStringAsFixed(2)} | LTP ${p.toStringAsFixed(2)}';
      }
    });
  }

  void close() {
    final p = double.tryParse(price.text);
    final entry = entryPrice;
    if (entry == null || p == null || p <= 0) return;
    setState(() {
      final pnl = p - entry;
      cash += pnl;
      realized += pnl;
      trades++;
      lastAction = 'MANUAL CLOSE @ ${p.toStringAsFixed(2)} | P&L ₹${pnl.toStringAsFixed(2)}';
      entryPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Paper Trading Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Virtual execution only. No broker order is sent.'),
        const SizedBox(height: 12),
        Card(child: ListTile(leading: Icon(killed ? Icons.block : running ? Icons.play_circle : Icons.pause_circle), title: Text(killed ? 'KILL SWITCH ACTIVE' : running ? 'RUNNING — PAPER ONLY' : 'PAUSED — PAPER ONLY'))),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Market Price', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(onPressed: killed ? null : () => setState(() { running = true; lastAction = 'Paper trading started'; }), child: const Text('Start')),
          OutlinedButton(onPressed: () => setState(() { running = false; lastAction = 'Paper trading paused'; }), child: const Text('Pause')),
          FilledButton.tonal(onPressed: killed ? null : () => setState(() { killed = true; running = false; lastAction = 'KILL SWITCH ACTIVATED'; }), child: const Text('Kill Switch')),
          OutlinedButton(onPressed: running && !killed ? tick : null, child: const Text('Process Tick')),
          OutlinedButton(onPressed: entryPrice != null ? close : null, child: const Text('Close')),
        ]),
        const SizedBox(height: 10),
        Card(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('Last Action'), subtitle: Text(lastAction))),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 8, children: [
          metric('Virtual Cash', '₹${cash.toStringAsFixed(2)}'),
          metric('Realized P&L', '₹${realized.toStringAsFixed(2)}'),
          metric('Trades', '$trades'),
          metric('Position', entryPrice == null ? 'None' : 'LONG @ ${entryPrice!.toStringAsFixed(2)}'),
        ]),
      ]);
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [
        Card(child: ListTile(leading: Icon(Icons.lock), title: Text('Real broker orders'), subtitle: Text('DISABLED'))),
        Card(child: ListTile(leading: Icon(Icons.lock), title: Text('Auto-Trading'), subtitle: Text('LOCKED'))),
        Card(child: ListTile(leading: Icon(Icons.account_balance_wallet), title: Text('Execution mode'), subtitle: Text('Paper / Virtual only'))),
        Card(child: ListTile(leading: Icon(Icons.warning_amber), title: Text('Kill Switch'), subtitle: Text('Available in Paper Trading'))),
      ]);
}

Widget metric(String title, String value) => SizedBox(width: 155, child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]))));

class CurvePainter extends CustomPainter {
  final List<double> values;
  const CurvePainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min), hi = values.reduce(math.max), range = (hi - lo).abs() < .000001 ? 1 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - (values[i] - lo) / range * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRect(Offset.zero & size, Paint()..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) => oldDelegate.values != values;
}
