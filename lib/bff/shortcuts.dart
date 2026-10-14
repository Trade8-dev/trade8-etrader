// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Keyboard shortcut system (A1.4): ShortcutMap registry with editable
// bindings synced to trader_profile.tool_preferences, F-key commit chain.
//
// 
// bindings map is persisted server-side via the Desk profile write;
// defaults mirror the desktop terminal layout.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One shortcut binding.
class ShortcutBinding {
 final String action;
 final LogicalKeyboardKey key;
 final String label;
 const ShortcutBinding(this.action, this.key, this.label);
}

/// Default bindings (the desktop terminal parity — F-key commit chain).
const Map<String, ShortcutBinding> kDefaultShortcuts = {
 'buy_limit': ShortcutBinding('buy_limit', LogicalKeyboardKey.keyF1, 'F1 — Buy limit'),
 'sell_limit': ShortcutBinding('sell_limit', LogicalKeyboardKey.keyF2, 'F2 — Sell limit'),
 'buy_market': ShortcutBinding('buy_market', LogicalKeyboardKey.keyF3, 'F3 — Buy market'),
 'sell_market': ShortcutBinding('sell_market', LogicalKeyboardKey.keyF4, 'F4 — Sell market'),
 'cancel_all': ShortcutBinding('cancel_all', LogicalKeyboardKey.keyF5, 'F5 — Cancel all working'),
 'flatten': ShortcutBinding('flatten', LogicalKeyboardKey.keyF6, 'F6 — Flatten position'),
 'refresh_blotter': ShortcutBinding('refresh_blotter', LogicalKeyboardKey.f9, 'F9 — Refresh blotter'),
 'focus_ticket': ShortcutBinding('focus_ticket', LogicalKeyboardKey.f10, 'F10 — Focus ticket'),
};

/// The shortcut registry: holds the active binding map, applies edits,
/// and serializes to/from trader_profile.tool_preferences (the sync
/// write lands with the profile API — the shape is fixed here).
class ShortcutMap {
 Map<String, LogicalKeyboardKey> bindings;

 ShortcutMap({Map<String, LogicalKeyboardKey>? initial})
 : bindings = initial ??
 {
 for (final e in kDefaultShortcuts.entries) e.key: e.value.key,
 };

 /// Deserialize from tool_preferences (the stored shape is the
 /// platform action name → physical key id).
 factory ShortcutMap.fromPrefs(Map<String, dynamic> prefs) {
 final raw = prefs['shortcuts'] as Map<String, dynamic>? ?? {};
 final initial = <String, LogicalKeyboardKey>{};
 for (final e in kDefaultShortcuts.entries) {
 final stored = raw[e.key];
 if (stored is int) {
 final key = LogicalKeyboardKey.findKeyByKeyId(stored);
 if (key != null) {
 initial[e.key] = key;
 continue;
 }
 }
 initial[e.key] = e.value.key;
 }
 return ShortcutMap(initial: initial);
 }

 /// Serialize to tool_preferences.
 Map<String, dynamic> toPrefs => {
 'shortcuts': {
 for (final e in bindings.entries) e.key: e.value.keyId,
 },
 };

 /// Invoke the action for a key press.
 void handleKey(LogicalKeyboardKey key, Map<String, void Function> actions) {
 for (final e in bindings.entries) {
 if (e.value == key) {
 actions[e.key]?.call;
 return;
 }
 }
 }
}