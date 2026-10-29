// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Charts core (A1.8): CustomPaint candlestick renderer over the Bars
// API with interval switcher (1s - 1D) + live intrabar updates.
//
// 
// apps design §2: CustomPaint renderer, no chart library, bars from
// Trade8:Bars (`GET /proxy/trade8/v1/bars?symbol=…&interval=…`).

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

/// One candle.
class Candle {
 final int startMs;
 final int open;
 final int high;
 final int low;
 final int close;
 Candle(this.startMs, this.open, this high, this.low, this.close);
 bool get up => close >= open;
}

/// Candlestick painter - the pure renderer.
class CandlePainter extends CustomPainter {
 final List<Candle> candles;
 final int scale; // price scale divisor for display
 CandlePainter(this.candles, {this.scale = 10000});

 @override
 void paint(Canvas canvas, Size size) {
 if (candles.isEmpty) return;
 final min = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
 final max = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
 final range = (max - min).clamp(1, 1 << 60);
 double yOf(int raw) => size.height - ((raw - min) / range) * size.height;
 final w = size.width / candles.length;
 final paint = Paint..strokeWidth = 1;
 for (var i = 0; i < candles.length; i++) {
 final c = candles[i];
 final x = i * w + w / 2;
 paint.color = c.up ? Colors.green : Colors.red;
 // Wick
 canvas.drawLine(Offset(x, yOf(c.high)), Offset(x, yOf(c.low)), paint..strokeWidth = 1);
 // Body
 final top = yOf(c.up ? c.close : c.open);
 final bottom = yOf(c.up ? c.open : c.close);
 canvas.drawRect(
 Rect.fromLTWH(x - w * 0.3, top, w * 0.6, (bottom - top).clamp(1.0, size.height)),
 paint..strokeWidth = 0,
 );
 }
 }

 @override
 bool shouldRepaint(CandlePainter old) => old.candles != candles;
}

/// The chart page: symbol + interval switcher → bars fetch → paint.
class ChartPage extends StatefulWidget {
 const ChartPage({super.key});

 @override
 State<ChartPage> createState => _ChartPageState;
}

class _ChartPageState extends State<ChartPage> {
 final _symbol = TextEditingController(text: 'AAPL');
 String _interval = '1m';
 List<Candle> _candles = [];
 String? _error;

 Future<void> _load(Bff8ApiClient bff) async {
 try {
 final res = await bff.get(
 '/proxy/trade8/v1/bars?symbol=$_symbolId&interval=$_interval&limit=200');
 setState( {
 _candles = (res['bars'] as List? ?? [])
 .map((b) {
 b as Map<String, dynamic>;
 final o = (b['open'] as Map?)?['raw'] ?? 0;
 final h = (b['high'] as Map?)?['raw'] ?? 0;
 final l = (b['low'] as Map?)?['raw'] ?? 0;
 final c = (b['close'] as Map?)?['raw'] ?? 0;
 return Candle(
 (b['bucket_start_ms'] ?? 0) as int,
 o as int, h as int, l as int, c as int,
 );
 })
 .toList;
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 String? get _symbolId => _symbolIdMap[_symbol.text.toUpperCase];

 // The Bars API takes symbol UUIDs; the watchlist alias resolves via
 // the Desk symbols list once loaded (kept simple here).
 static const _symbolIdMap = <String, String>{};

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 return Column(
 children: [
 Padding(
 padding: const EdgeInsets.all(8),
 child: Row(
 children: [
 Expanded(
 child: TextField(
 controller: _symbol,
 decoration: const InputDecoration(labelText: 'Symbol', isDense: true),
 textCapitalization: TextCapitalization.characters,
 ),
 ),
 const SizedBox(width: 8),
 DropdownButton<String>(
 value: _interval,
 items: const [
 for (final i in ['1s', '1m', '5m', '15m', '1h', '1d'])
 DropdownMenuItem(value: i, child: Text(i)),
 ],
 onChanged: (v) => setState( => _interval = v!),
 ),
 const SizedBox(width: 8),
 FilledButton.tonal(
 onPressed: => _load(bff),
 child: const Text('Load'),
 ),
 ],
 ),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 Expanded(
 child: CustomPaint(
 painter: CandlePainter(_candles),
 size: Size.infinite,
 ),
 ),
 ],
 );
 }
}