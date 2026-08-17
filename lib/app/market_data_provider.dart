import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketCandle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const MarketCandle(this.open, this.high, this.low, this.close, this.volume);
}

class MarketDataResult {
  final List<MarketCandle> candles;
  final String requestedSymbol;
  final String resolvedSymbol;
  final String source;

  const MarketDataResult({
    required this.candles,
    required this.requestedSymbol,
    required this.resolvedSymbol,
    required this.source,
  });
}

/// India-first market data provider using Yahoo Finance's chart endpoint.
/// This endpoint does not require a client API key. It is an unofficial/public
/// endpoint, so production use should later be upgraded to a licensed feed.
class MarketDataProvider {
  const MarketDataProvider();

  Future<MarketDataResult> fetch({
    required String inputSymbol,
    required String timeframe,
  }) async {
    final requested = inputSymbol.trim().toUpperCase();
    if (requested.isEmpty) throw Exception('Enter a market symbol.');

    final resolved = _resolveSymbol(requested);
    final interval = _yahooInterval(timeframe);
    final range = _yahooRange(timeframe);

    final uri = Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/$resolved', {
      'interval': interval,
      'range': range,
      'includePrePost': 'false',
      'events': 'div,splits',
    });

    final response = await http.get(uri, headers: const {
      'User-Agent': 'MasterTradingEngine/3.1',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} from market-data provider');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final chart = body['chart'] as Map<String, dynamic>?;
    final error = chart?['error'];
    if (error != null) {
      throw Exception('Market-data provider rejected $requested');
    }

    final results = chart?['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw Exception('No market data returned for $requested');
    }

    final result = results.first as Map<String, dynamic>;
    final timestamps = (result['timestamp'] as List<dynamic>? ?? []);
    final quote = ((result['indicators'] as Map<String, dynamic>?)?['quote'] as List<dynamic>? ?? []);
    if (quote.isEmpty) throw Exception('No OHLCV data returned for $requested');

    final q = quote.first as Map<String, dynamic>;
    final opens = q['open'] as List<dynamic>? ?? [];
    final highs = q['high'] as List<dynamic>? ?? [];
    final lows = q['low'] as List<dynamic>? ?? [];
    final closes = q['close'] as List<dynamic>? ?? [];
    final volumes = q['volume'] as List<dynamic>? ?? [];

    final candles = <MarketCandle>[];
    final count = [timestamps.length, opens.length, highs.length, lows.length, closes.length]
        .reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < count; i++) {
      final o = _number(opens[i]);
      final h = _number(highs[i]);
      final l = _number(lows[i]);
      final c = _number(closes[i]);
      final v = i < volumes.length ? _number(volumes[i]) : null;
      if (o == null || h == null || l == null || c == null) continue;
      candles.add(MarketCandle(o, h, l, c, v ?? 0.0));
    }

    if (candles.length < 30) {
      throw Exception('Only ${candles.length} usable candles returned; at least 30 are required.');
    }

    return MarketDataResult(
      candles: candles,
      requestedSymbol: requested,
      resolvedSymbol: resolved,
      source: 'Yahoo Finance Chart API',
    );
  }

  String _resolveSymbol(String symbol) {
    switch (symbol.replaceAll(RegExp(r'\s+'), ' ')) {
      case 'NIFTY':
      case 'NIFTY 50':
      case 'NIFTY50':
        return '^NSEI';
      case 'BANK NIFTY':
      case 'BANKNIFTY':
      case 'NIFTY BANK':
        return '^NSEBANK';
      case 'SENSEX':
      case 'BSE SENSEX':
        return '^BSESN';
    }

    if (symbol.startsWith('^') || symbol.endsWith('.NS') || symbol.endsWith('.BO') || symbol.contains('-')) {
      return symbol;
    }

    return '$symbol.NS';
  }

  String _yahooInterval(String timeframe) {
    switch (timeframe) {
      case '1m':
        return '1m';
      case '5m':
        return '5m';
      case '15m':
        return '15m';
      case '1h':
        return '1h';
      case '1d':
        return '1d';
      default:
        throw Exception('Unsupported timeframe $timeframe');
    }
  }

  String _yahooRange(String timeframe) {
    switch (timeframe) {
      case '1m':
        return '5d';
      case '5m':
        return '1mo';
      case '15m':
        return '3mo';
      case '1h':
        return '1y';
      case '1d':
        return '5y';
      default:
        return '1mo';
    }
  }

  double? _number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
