// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Realtime store (A1.2): SSE subscription manager with per-topic seq,
// gap detection → snapshot refetch banner state, auto re-subscribe.
//
// The transport stream comes from the sentin8_flutter SSE surface
// (`/subscribe?channel=trade8:feed:quote:updated`-style topics); this
// store dedupes by seq, detects gaps (seq +1 expected), and flips a
// banner state the app shell renders as "resyncing…" until the
// snapshot refetch completes.

import 'dart:async';

import 'bff_client.dart';

/// Realtime store state for the banner.
enum RealtimeState { live, resyncing, disconnected }

/// The realtime store: one subscription per topic with seq tracking.
class RealtimeStore {
 final Bff8ApiClient bff;
 final _controller = StreamController<RealtimeState>.broadcast;
 final Map<String, int> _lastSeq = {};
 final Map<String, void Function(Map<String, dynamic>)> _handlers = {};
 final List<StreamSubscription> _subs = [];
 RealtimeState _state = RealtimeState.live;

 RealtimeStore(this.bff);

 Stream<RealtimeState> get state => _controller.stream;
 RealtimeState get current => _state;

 /// Subscribe to a topic with a payload handler. Gap → snapshot refetch
 /// (the caller passes the refetch callback) → banner clears.
 void subscribe(
 String topic,
 void Function(Map<String, dynamic>) onEvent, {
 required Future<void> Function onGap,
 }) {
 _handlers[topic] = (data) {
 final seq = (data['seq'] as num?)?.toInt ?? 0;
 final last = _lastSeq[topic] ?? 0;
 if (last > 0 && seq > last + 1) {
 // Gap detected: snapshot refetch + banner, then deliver.
 _setState(RealtimeState.resyncing);
 onGap.then((_) => _setState(RealtimeState.live));
 }
 _lastSeq[topic] = seq;
 onEvent(data['payload'] as Map<String, dynamic>? ?? data);
 };
 final sub = bff.subscribe(topic).listen(
 (ev) => _handlers[topic]?.call(ev.data),
 onError: (_) => _setState(RealtimeState.disconnected),
 onDone: => _setState(RealtimeState.disconnected),
 );
 _subs.add(sub);
 }

 /// Snapshot refetch helper - call after a gap or on cold start.
 Future<void> refetch(Future<void> Function fetcher) async {
 _setState(RealtimeState.resyncing);
 await fetcher;
 _setState(RealtimeState.live);
 }

 void _setState(RealtimeState s) {
 if (_state != s) {
 _state = s;
 _controller.add(s);
 }
 }

 Future<void> dispose async {
 for (final s in _subs) {
 await s.cancel;
 }
 await _controller.close;
 }
}