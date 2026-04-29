# SillMemeFightGame — UI Layout & Visual Style

## Full UI Layout

- **Top-left**: Combat log (small, color-coded, 5 lines max)
- **Top-right**: Enemy HP bar + intent label (`"Attack: X → Part"`)
- **Middle**: Battlefield (6 slots with character sprites)
- **Left column (mid-lower)**: Player body highlight — colored zones showing player body part health; flashes on hit
- **Right column (mid-lower)**: Enemy body highlight — colored zones; valid targets glow on attack select
- **Bottom-left**: Player panel (compact)
- **Bottom-right**: End Turn button (always visible)
- **Above hand**: Action tracker `[ Move: — ]  [ Attack: — ]  [ Guard: — ]`
- **Bottom-center**: Card hand split into 3 sections — Movement | Attack | Guard

---

## Combat Log Colors

- Red `(1, 0.4, 0.4)` — player attack hits / fatal warnings
- Yellow `(1, 0.8, 0.2)` — body part status changes, sub-part effects
- Blue `(0.4, 0.7, 1)` — enemy actions
- Gray `(0.8, 0.8, 0.8)` — info messages

---

## Body Highlight Visual Style

- Colored zone panels represent each body part, positioned on a silhouette of the character
- Color reflects current body part status: Green (HEALTHY), Yellow (BRUISED), Orange (BROKEN), Red (DISABLED)
- Zones flash briefly when that part takes damage
- hoofd/borst zones pulse red when a damaged fatal organ is inside them
- On attack select: valid target zones glow; invalid zones grey out
- Both player and enemy have their own body selector, positioned above the End Turn button area

---

## Tooltip System

- Both body selectors support hover tooltips
- Tooltip shows body part name, current HP, status, and any active sub-part effects
- Displayed on mouse-over of a body zone

---

## Card Tab System

Three clickable tabs sit directly above the card hand area. Only the active tab's cards are shown at once.

**Tab bar:** `[ Movement ]  [ Attack ]  [ Guard ]`

- **Default active tab** on turn start: Movement
- **Active tab**: bright border, slightly larger top border, full opacity
- **Inactive tabs**: dimmed (55% opacity)
- **Completed tab**: grey background, checkmark appended — `[ Attack ✓ ]`; cards still shown but all greyed out and unclickable

**Auto-advance behavior:**
- After movement confirmed → switch to Attack tab
- After attack confirmed → switch to Guard tab
- After all three done → tabs show all ✓; End Turn prompt visible
- Player can manually click any tab at any time

**Visual tints:**
- Movement tab: blue `(0.18, 0.32, 0.75)`
- Attack tab: red `(0.72, 0.14, 0.14)`
- Guard tab: green `(0.14, 0.52, 0.18)`
- Completed tab: grey `(0.22, 0.22, 0.25)`

**Card animation:** cards slide up from below (0.15 s, 0.025 s stagger per card) when switching tabs.

**Script:** `scripts/card_tabs.gd` — manages tabs, card_area container, and tab state. Called by `battle_ui.gd` via `setup(battle)` and `refresh_tab_state()`.

---

## Action Tracker

- Positioned above the tab bar (28 px above the CardTabs node)
- Format: `[ Move: Forward ✓ ]  [ Attack: Roundhouse → hoofd ✓ ]  [ Guard: — ]`
- Fills in as actions are confirmed (e.g. `[ Move: Forward ✓ ]`)
- Once an action slot is confirmed, it locks and cannot be changed
- Unconfirmed slots show `—`

---

## Combat Popup System

Large centered popups mirror every combat log entry, providing at-a-glance feedback on significant events.

**Position:** Center of battlefield, slightly above vertical screen center (`x=576, y=310` in screen coordinates). Sits on its own `CanvasLayer` (layer 10) above all other UI — never blocked by any element.

**Script:** `scripts/combat_popup.gd` — self-contained Control node with an internal message queue and state machine (`idle → fade_in → showing → fade_out`).

**Visual style:**
- Font: 36 px (≈ 3× combat log size), bold, centered
- Same color coding as the combat log (Red / Yellow / Blue / Gray)
- Background: dark semi-transparent pill — `Color(0.1, 0.1, 0.1, 0.7)`, 14 px corner radius
- Pill size: 760 × 60 px, centered on the anchor point

**Timing & animation:**
- Animates in: slides up 20 px + fades in over 0.15 s
- Stays visible for 3 seconds
- Fades out over 0.3 s
- Next queued message starts immediately after the fade-out completes

**Queueing:**
- Every `add_entry()` call in `CombatLog` calls `popup.show_message(text, color)`
- `CombatPopup` is found via the `"combat_popup"` group (no hard-wired node path)
- If idle when a message arrives → shows immediately
- If busy → message is queued; all queued messages play sequentially (3 s each)
- Rapid sub-part hits produce a chain of popups shown one after another

---

## Body Selector Positioning

- Player body highlight: left column, mid-lower area of the screen
- Enemy body highlight: right column, mid-lower area of the screen
- Both positioned above the End Turn button
