# etrader — Trade8 Professional Trading App

> Audience: product owners and business stakeholders. For architecture
> read `README.md`; for the platform app contract read
> `design/sentin8-trade8-apps-technical-design.md`.

## 1. Business Purpose

- Put the **entire trading desk in the trader's hands**: enter, manage, and
  monitor orders; watch the market ladder and tape; track P&L — on one
  keyboard-dense, sub-second surface.
- Deliver it **safely on any device**: the app holds no credentials and can
  never move money without the server-side authorization plane.
- Support the **muscle memory of professional traders** — F-key chains,
  deterministic behavior, immediate feedback — and carry those preferences
  across devices.

## 2. Business Scope (What the App Provides)

| Capability | Description |
|---|---|
| Order entry (ticket) | Typeahead symbol entry, side/quantity/price steppers honoring tick bands, destination + TIF selection, idempotent submissions |
| Blotter | Working/terminal order views, cancel, per-order status |
| Depth ladder | Live L2 ladder with sizes at each level |
| Tape / watchlist | Live prints and quotes for watched symbols |
| Charts | Candlesticks (client-drawn), intervals 1s–1D, MA/EMA/VWAP overlays |
| P&L board | Per-symbol and total day P&L, LFT giveback |
| Alerts | Rule creation + fired-alert display with acknowledge |
| Flatten sheet | Typed flatten strategy parameters + basket progress |
| Settings | Shortcut editor synced to the trader profile; keystroke/audit view |
| Keyboard trading | The F-key chain (buy/sell limit & market, cancel all, flatten, refresh, focus) |
| Realtime resilience | Sequence-gap detection with visible resync state; reconnect banner |

### What the app does NOT own (business boundary)

| Concern | Owned by |
|---|---|
| Authentication/identity | Sentin8:Auth via BFF |
| Authorization decisions | Shield policies (services) |
| Tokens/OAuth | Sentin8:BFF (server-side) |
| All trading business rules | trade8 services |
| App-store presence/packaging | Sentin8:App (`app-listing.json`) |

## 3. Business Capabilities

| Area | Capability | Business rule |
|---|---|---|
| Entry | Tick-band steppers | The pad offers only prices on-tick for the instrument (0.01 <$5, 0.05 ≥$5 bands) |
| Entry | Idempotent submissions | A retried submit cannot duplicate an order |
| Entry | Session awareness | Entry surfaces the session state (rejects outside open are explicit, not silent) |
| Monitoring | Scope-correct blotter | Traders see their orders; managers see their office (per service scopes) |
| Realtime | Truthful resync | On a data gap the app shows "resyncing" and refetches a snapshot — it never invents liquidity or prints |
| P&L | Self-tier numbers | Traders see only their own P&L by default |
| Alerts | Declarative + acknowledged | Rules are simple comparisons; fired alerts persist until acknowledged |
| Flatten | Typed strategies | Flatten params are validated forms, not free text |

## 4. Business Events (Outbound)

The app emits no platform events; it *initiates* trading actions (order
submissions/cancels) and *consumes* streams:

| Consumed surface | Content |
|---|---|
| SSE quote stream | Snapshot + live BBO frames (per-topic sequence) |
| Blotter/PnL channels | Order and summary updates |
| Alert channel | Fired alerts |

## 5. Business Rules & Invariants

1. The app never bypasses the BFF — one transport, zero direct service
   calls.
2. No money formatting via floats — scaled integer input/output only.
3. Every destructive action (cancel, cancel all, flatten) is explicit and
   confirms in the UI, with the result journaled server-side.
4. Scope-gated surfaces: a page a user cannot use is hidden, not erroring.
5. Client order ids are generated once per intent — refresh loops are safe.

## 6. Target-User Roles & Use Cases

| Persona | Use cases |
|---|---|
| Trader | Everything: enter/exit positions, watch the ladder, track P&L, set alerts |
| Office manager | The office blotter/P&L view (scope-gated) |
| Desk supervisor | Session view, order-state review (read surfaces) |
| New traders | Guided ticket defaults from the trader profile |

## 7. KPIs / Success Criteria

- Time-to-first-order for a new session measured in seconds (keyboard-first
  flows).
- Zero stale-price trades: quotes/tape visibly resync on gaps.
- The F-key chain performs within the platform's UI latency budget.
- Crash-free sessions on all delivery surfaces (web/mobile).

## 8. Dependencies & Reliance on Other Services

| Dependency | Why the app relies on it |
|---|---|
| Sentin8:BFF | The only transport (proxy + SSE/WS) |
| Trade8:Desk | Orders/session/blotter |
| Trade8:Feed | Quotes/depth/alerts/prints |
| Trade8:Pnl | P&L board |
| Trade8:Bars | Chart history |
| `sentin8_flutter` bootstrap | Authenticated transport + theme |
| Sentin8:App | Distribution (`app-listing.json`) |

## 9. Acceptance Criteria

1. A trader can buy and sell through the ticket end-to-end and see fills in
   blotter and P&L.
2. The ladder and tape update live and recover from reconnects visibly.
3. Cancelling everything (F5) is a single keystroke with confirmation.
4. Flatten produces visible strategy progress and results.
5. A user lacking depth entitlement never sees the ladder.

## 10. Open Business Questions

- Should the ladder support click-to-trade pre-fill at launch?
- Do managers need cross-trader flatten approval UX in v1?
- Mobile-specific trading flows (touch order pad) — same surfaces or
  simplified?
- Should the app show audit/keystroke history to traders (their own) or
  only to admins?

---

**Design attribution:** trade8:etrader and its underlying concepts were designed by Hamid Jahanzad <Hamid@Jahanzad.com>.
