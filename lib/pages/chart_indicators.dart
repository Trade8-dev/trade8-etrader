// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Charts indicators + overlays (A1.9): pure-Dart SMA/EMA/Bollinger/CCI
// over the candle series (no external package — the renderer owns its
// math), plus overlay painters for order-price lines, fill markers,
// position shading, trendline/hline basics.
//
// 
// design §2 (CustomPaint overlays, indicator values as dart doubles).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart.dart';

// ---------------------------------------------------------------------------
// Indicator math (pure functions over the close series)
// ---------------------------------------------------------------------------

/// Simple moving average.
List<double> sma(List<double> values, int period) {
 final out = List<double>.filled(values.length, 0);
 var sum = 0.0;
 for (var i = 0; i < values.length; i++) {
 sum += values[i];
 if (i >= period) sum -= values[i - period];
 if (i >= period - 1) out[i] = sum / period;
 }
 return out;
}

/// Exponential moving average (seeded with the SMA of the first period).
List<double> ema(List<double> values, int period) {
 final out = List<double>.filled(values.length, 0);
 if (values.length < period) return out;
 final k = 2.0 / (period + 1);
 var seed = 0.0;
 for (var i = 0; i < period; i++) {
 seed += values[i];
 }
 out[period - 1] = seed / period;
 for (var i = period; i < values.length; i++) {
 out[i] = values[i] * k + out[i - 1] * (1 - k);
 }
 return out;
}

/// Bollinger bands (middle SMA ± n·σ).
({List<double> upper, List<double> middle, List<double> lower}) bollinger(
 List<double> values, int period, {double deviations = 2.0}) {
 final middle = sma(values, period);
 final upper = List<double>.filled(values.length, 0);
 final lower = List<double>.filled(values.length, 0);
 for (var i = period - 1; i < values.length; i++) {
 var varSum = 0.0;
 for (var j = i - period + 1; j <= i; j++) {
 varSum += math.pow(values[j] - middle[i], 2);
 }
 final sd = math.sqrt(varSum / period);
 upper[i] = middle[i] + deviations * sd;
 lower[i] = middle[i] - deviations * sd;
 }
 return (upper: upper, middle: middle, lower: lower);
}

/// CCI (Commodity Channel Index) — typical price vs its SMA.
List<double> cci(List<Candle> candles, int period) {
 final tp = candles
 .map((c) => ((c.high + c.low + c.close) / 3.0) / 10000.0)
 .toList;
 final out = List<double>.filled(candles.length, 0);
 final ma = sma(tp, period);
 for (var i = period - 1; i < tp.length; i++) {
 var meanDev = 0.0;
 for (var j = i - period + 1; j <= i; j++) {
 meanDev += (tp[j] - ma[i]).abs;
 }
 meanDev /= period;
 out[i] = meanDev == 0 ? 0 : (tp[i] - ma[i]) / (0.015 * meanDev);
 }
 return out;
}

// ---------------------------------------------------------------------------
// Overlay painters
// ---------------------------------------------------------------------------

/// One overlay line (indicator output or price level).
class OverlayLine {
 final List<double> values;
 final Color color;
 final double width;
 final double yScale; // raw→display divisor (10000 for ×10⁴ prices)
 const OverlayLine(this.values, this.color, {this.width = 1.0, this.yScale = 10000.0});
}

/// Indicators + overlays painter — draws above the candles.
class OverlayPainter extends CustomPainter {
 final List<Candle> candles;
 final List<OverlayLine> lines;
 final double minRaw;
 final double maxRaw;

 OverlayPainter(this.candles, this.lines, {required this.minRaw, required this.maxRaw});

 @override
 void paint(Canvas canvas, Size size) {
 final range = (maxRaw - minRaw).clamp(1.0, 1.0e18);
 double yOf(double raw) => size.height - ((raw - minRaw) / range) * size.height;
 final w = candles.isEmpty ? 1.0 : size.width / candles.length;
 for (final line in lines) {
 final paint = Paint
 ..color = line.color
 ..strokeWidth = line.width
 ..style = PaintingStyle.stroke;
 final path = Path;
 var started = false;
 for (var i = 0; i < line.values.length && i < candles.length; i++) {
 final v = line.values[i];
 if (v == 0) continue;
 final x = i * w + w / 2;
 final y = yOf(v * line.yScale);
 if (!started) {
 path.moveTo(x, y);
 started = true;
 } else {
 path.lineTo(x, y);
 }
 }
 canvas.drawPath(path, paint);
 }
 }

 @override
 bool shouldRepaint(OverlayPainter old) => old.candles != candles || old.lines != lines;
}

/// Order/fill markers + position shading painter (A1.9 overlays).
class TradeOverlayPainter extends CustomPainter {
 final List<Candle> candles;
 /// Fill markers: (candleIndex, priceRaw, isBuy).
 final List<(int, int, bool)> fills;
 /// Order price lines (raw) — limit levels rendered as horizontal dashes.
 final List<int> priceLines;
 /// Position shading: (fromCandle, toCandle) long/short band.
 final (int, int, bool)? positionBand;
 final double minRaw;
 final double maxRaw;

 TradeOverlayPainter(
 this.candles, {
 required this.fills,
 required this.priceLines,
 required this.positionBand,
 required this.minRaw,
 required this.maxRaw,
 });

 @override
 void paint(Canvas canvas, Size size) {
 final range = (maxRaw - minRaw).clamp(1.0, 1.0e18);
 double yOf(double raw) => size.height - ((raw - minRaw) / range) * size.height;
 final w = candles.isEmpty ? 1.0 : size.width / candles.length;
 // Position shading.
 if (positionBand case (final from, final to, final long)) {
 final rect = Rect.fromLTWH(from * w, 0, (to - from + 1) * w, size.height);
 canvas.drawRect(
 rect,
 Paint
 ..color = (long ? Colors.green : Colors.red).withValues(alpha: 0.08),
 );
 }
 // Price lines (dashed approximation: thin solid).
 for (final raw in priceLines) {
 final y = yOf(raw.toDouble);
 canvas.drawLine(
 Offset(0, y),
 Offset(size.width, y),
 Paint
 ..color = Colors.amber.withValues(alpha: 0.7)
 ..strokeWidth = 0.8,
 );
 }
 // Fill markers (triangles above/below).
 for (final (i, raw, isBuy) in fills) {
 final x = i * w + w / 2;
 final y = yOf(raw.toDouble);
 final c = isBuy ? Colors.green : Colors.red;
 final path = Path
 ..moveTo(x, y + (isBuy ? 10 : -10))
 ..lineTo(x - 5, y + (isBuy ? 18 : -18))
 ..lineTo(x + 5, y + (isBuy ? 18 : -18))
 ..close;
 canvas.drawPath(path, Paint..color = c);
 }
 }

 @override
 bool shouldRepaint(TradeOverlayPainter old) =>
 old.candles != candles || old.fills != fills || old.priceLines != priceLines;
}