# SillMemeFightGame — Design Plan

## Overview
A turn-based card fighting game built in Godot 4. Two characters fight on a 6-slot battlefield. Each turn both sides plan 3 actions simultaneously (movement, attack, defense) and resolve them all at once.

---

## Characters

### Kickboxer (active)
- HP: 80 | Energy: n/a
- Deck: full attack roster available every turn (Jab, Hook, Uppercut, Overhand, Backfist, Roundhouse Kick, Front Kick, Spinning Heel Kick)
- Character image: `assets/cards/Kickbokser.png`

### Streamer (disabled — coming soon)
- HP: 65 | Energy: 4
- Deck: Arrows, Shield, Gun combo chain

---

## Turn Structure — Simultaneous Free-Order System

Each turn both the player and the enemy independently choose 3 actions: **1 movement, 1 attack, 1 defense** — in any order. Once the player confirms all 3 (or clicks End Turn), both sides resolve simultaneously.

### Player Planning Phase
- All 3 card types are available in hand at once: movement cards (left), attack cards (center), guard cards (right)
- Player can play them in any order
- Action tracker above hand: `[ Move: — ]  [ Attack: — ]  [ Guard: — ]` — fills in as actions are chosen
- Once an action type is used it is **locked** — player cannot change it; used card shows a ✓ overlay
- **End Turn** button is always visible — clicking it skips any remaining unused actions
- Turn auto-confirms when all 3 actions are used

### Enemy Planning (hidden)
- Enemy secretly picks all 3 actions at the start of the player's planning phase
- **Movement**: random (Forward / Stance / Back) weighted toward closing distance
- **Attack**: picks from the full attack roster filtered by current range; target body part shown in intent label as `"Attack: X → [part]"`
- **Defense**: random guard card — NOT shown to player
- Intent label shows attack only — enemy movement and guard remain hidden

### Simultaneous Resolution Order
1. **Both movement actions resolve** — positions update, "Both fighters move." logged if any movement
2. **Range check** — new distance calculated after movement
3. **Both attack actions resolve** — range checked against post-movement distance; out-of-range = miss
4. **Both defense actions resolve** — guard match check, chip damage applied
5. **Fatal organ checks** — after all damage, check win/loss conditions

### Out-of-Range Rules
- If player moved out of attack range → player attack misses; gray log: *"Moved out of range — attack missed!"*
- If enemy moved out of attack range → enemy attack misses; blue log: *"Enemy moved out of range — attack missed!"*
- Moving away does **not** dodge — only guarding does

### Defense Resolution
- Player guard: click a guard card → immediately locked in; no body zone click needed
- Enemy guard: secretly chosen random body part at turn start
- If guard matches incoming attack part → block; chip damage `ceili(dmg × 0.2)` applied to guarding limb
- If guarding limb is DISABLED → block fails; full damage goes through (red warning)
- If guarding limb is BRUISED/BROKEN → block succeeds, chip damage doubled (yellow warning)
- If both sides guarded correctly → both blocks succeed independently

### Combat Log During Resolution
- Gray: `"--- Turn resolving ---"`
- Gray: `"Both fighters move."` (if any movement)
- Attack and defense messages follow as normal

---

## Attack Roster (Full — Kickboxer)

| Card | Limb | Range | Targets & Damage | Special |
|------|------|-------|-----------------|---------|
| **Jab** | linkerarm | 2–3 | hoofd 6, borst 5 | — |
| **Hook** | rechterarm | 1 | hoofd 12+stun, borst 10 | stun on hoofd |
| **Uppercut** | rechterarm | 1 | hoofd 14+stun, borst 8 | stun on hoofd |
| **Overhand** | rechterarm | 1–2 | hoofd 10 | 50% bypass enemy guard; log red: *"Overhand crashes through the guard!"* |
| **Backfist** | linkerarm | 2–3 | hoofd 8 | brain sub-part base chance +0.15 for this attack; log: *"The backfist rattles the skull directly!"* |
| **Roundhouse Kick** | voeten | 2–3 | hoofd 10+stun, borst 8, bovenbenen 6+weaken, voeten 4+stun | weaken on bovenbenen |
| **Front Kick** | bovenbenen | 2–3 | borst 7, bovenbenen 6 | pushes enemy back 1 slot after hit; log gray: *"Enemy stumbles back!"* |
| **Spinning Heel Kick** | voeten | 3–4 | hoofd 16+stun | if miss → player stagger_turns=1 (no movement next turn); log red: *"Missed the spinning heel kick — you stumble!"* |

---

## Combat Mechanics

### Range
Each attack card has `min_range` / `max_range` in slots of distance between player and enemy. Out-of-range attack cards are grayed out and unselectable during planning. Range is rechecked after movement during resolution — attack misses if now out of range.

### Body Part Damage System
Each character's body parts have their own HP and progress through four statuses:

| Status | HP threshold | Colour |
|--------|-------------|--------|
| HEALTHY | > 50% | Green |
| BRUISED | 25–50% | Yellow |
| BROKEN | > 0% | Orange |
| DISABLED | 0 | Red |

Body parts and HP:
- `hoofd` (head): 15 HP
- `borst` (chest): 30 HP
- `linkerarm` / `rechterarm` (arms): 20 HP each
- `bovenbenen` (upper legs): 20 HP
- `voeten` (feet): 20 HP

Hitting an arm reduces `intent_damage` only when the arm's status changes.

### Fatal Organ System
Win/loss is determined entirely by fatal organ destruction — no global HP bars.

**Fatal organs (player and enemy):**
| Organ | Location | Type | HP | Base chance | Trigger |
|-------|----------|------|----|-------------|---------|
| Hart (Heart) | borst | Binary | 1 | 8% | Instant death on first hit |
| Hersenen (Brain) | hoofd | Degrading | 3 | 15% | Death at 0 HP |
| Wervelkolom (Spine) | borst | Degrading | 2 | 12% | Death at 0 HP |

Brain stages: HEALTHY(3) → CONCUSSED(2) → CRITICAL(1) → DESTROYED(0). Brain damage forces a random attack card next turn (concussion effect).
Spine stages: HEALTHY(2) → COMPRESSED(1) → DESTROYED(0).

**Danger indicators:** hoofd/borst body highlight zones pulse red when a damaged fatal organ is inside.

### Sub-Part System
Each body part contains sub-parts with base hit chance scaled by parent status:

| Parent Status | Chance multiplier |
|---------------|-------------------|
| HEALTHY | 1.0× |
| BRUISED | 1.5× |
| BROKEN | 2.5× |
| DISABLED | 0 (no rolls) |

Sub-parts per body part:

| Parent | Sub-part | Chance | Enemy effect | Player effect |
|--------|----------|--------|-------------|---------------|
| hoofd | Kaak/Jaw | 40% | skip 1 attack | skip 1 attack |
| hoofd | Hersenen/Brain | 15% | random target 2 turns | random attack forced 2 turns |
| borst | Ribben/Ribs | 50% | 1 self-damage per attack | 1 self-damage per attack |
| borst | Long/Lung | 25% | -3 damage 2 turns | draw 1 fewer 2 turns |
| borst | Hart/Heart | 8% | instant death | instant death |
| borst | Wervelkolom/Spine | 12% | instant death at 0 | instant death at 0 |
| linkerarm/rechterarm | Elleboog/Elbow | 30% | -2 damage next attack | -2 damage next attack |
| linkerarm/rechterarm | Pols/Wrist | 25% | 50% miss next attack | 50% miss next attack |
| bovenbenen/voeten | Knieschijf/Kneecap | 35% | enemy stationary 2 turns | can't move 2 turns |
| bovenbenen/voeten | Dijbeen/Thigh | 30% | -2 intent_damage (perm) | reserved |

### Status Effects
| Effect | Description |
|--------|-------------|
| Stun | Enemy skips next attack; picks a new target |
| Weaken | Reduces enemy's intent_damage by `value` |
| Stagger | Player cannot use movement cards next turn (Spinning Heel miss) |

### Limb Penalty System

**Attack penalties** — before resolving, check the attacking limb's status:
| Limb status | Damage multiplier |
|-------------|------------------|
| HEALTHY | 1.0× |
| BRUISED | 0.85× |
| BROKEN | 0.6× |
| DISABLED | 0.4× (pushes through pain) |

Attack limb mapping:
- Jab → linkerarm
- Hook / Uppercut / Overhand → rechterarm
- Backfist → linkerarm
- Roundhouse Kick / Spinning Heel Kick → voeten
- Front Kick → bovenbenen

**Defense penalties:**
- Any required limb DISABLED → block fails entirely; red log warning
- Any required limb BRUISED/BROKEN → block succeeds; chip damage doubled; yellow log warning

Guard limb requirements:
- Guard Head → both arms (linkerarm, rechterarm)
- Guard Chest → linkerarm
- Guard Upper Legs → bovenbenen
- Guard Feet → voeten

**Card visual feedback:**
- Attack card with BRUISED/BROKEN limb → orange `!` indicator
- Attack card with DISABLED limb → red `!` indicator
- Guard card with DISABLED required limb → semi-transparent overlay + red "DISABLED" label

### Defense (chip damage)
Binary block: guard the correct part → 0 damage to body, but chip damage `ceili(intent_damage × 0.2)` applies to the guarding limb:
- Guard Head → linkerarm absorbs chip
- Guard Chest → rechterarm absorbs chip
- Guard Upper Legs → bovenbenen absorbs chip
- Guard Feet → voeten absorbs chip

If the limb is DISABLED, chip goes to the body part directly. Chip triggers limb status changes and sub-part rolls normally.

---

## Enemy AI
- Starts at slot 4; can move each turn (weighted toward closing to mid-range)
- Picks from full attack roster filtered by current range
- Intent label shows: `"Attack: X → BodyPart"` (attack + target only; movement and guard remain hidden)
- Stun causes it to skip attack and pick a new target
- Enemy stagger (from own Spinning Heel miss or kneecap sub-part hit) blocks movement for the stagger duration

---

## Battlefield
- 6 slots (positions 0–5)
- Player starts at slot 2, enemy starts at slot 4 (distance 2 — in range for Jab/Backfist/Roundhouse/Front Kick)
- Both characters animate movement with smooth tweens; player lunges on combo land

---

## UI Layout
- **Top-left**: Combat log (small, color-coded, 5 lines max)
- **Top-right**: Enemy HP bar + intent label (`"Attack: X → Part"`)
- **Middle**: Battlefield (6 slots with character sprites)
- **Left column (mid-lower)**: Player body highlight — colored zones showing player body part health; flashes on hit
- **Right column (mid-lower)**: Enemy body highlight — colored zones; valid targets glow on attack select
- **Bottom-left**: Player panel (compact)
- **Bottom-right**: End Turn button (always visible)
- **Above hand**: Action tracker `[ Move: — ]  [ Attack: — ]  [ Guard: — ]`
- **Bottom-center**: Card hand split into 3 sections — Movement | Attack | Guard

### Combat Log Colors
- Red `(1, 0.4, 0.4)` — player attack hits / fatal warnings
- Yellow `(1, 0.8, 0.2)` — body part status changes, sub-part effects
- Blue `(0.4, 0.7, 1)` — enemy actions
- Gray `(0.8, 0.8, 0.8)` — info messages

---

## Completed
- [x] Simultaneous free-order turn system (Move / Attack / Guard planned together, resolved at once)
- [x] Action tracker UI above hand — fills in as actions chosen, ✓ checkmark on used card
- [x] 3-section card hand — Movement left, Attack center, Guard right; section greys out when action used
- [x] End Turn button always visible — skips remaining unused actions
- [x] Full new attack roster: Jab, Hook, Uppercut, Overhand, Backfist, Roundhouse Kick, Front Kick, Spinning Heel Kick
- [x] Overhand 50% guard bypass — log red: "Overhand crashes through the guard!"
- [x] Backfist brain boost — +0.15 brain sub-part chance for that hit
- [x] Front Kick push — enemy pushed 1 slot back after hit
- [x] Spinning Heel Kick miss — player stagger_turns=1, blocks movement next turn
- [x] Enemy mobile — plans movement, attack, and guard simultaneously with player
- [x] Enemy guard system — enemy secretly guards a random part; player attacks that part deal chip damage only
- [x] Body part renaming — bovenbenen (upper legs) and voeten (feet) replace linkerbeen/rechterbeen as body zones
- [x] Kickboxer character with full fixed hand per phase
- [x] Body part combos with stun / weaken effects
- [x] Valid zones highlight on attack select; invalid zones grey out
- [x] Range system — out-of-range cards grayed out; post-movement range recheck causes misses
- [x] Battlefield movement (Back / Stance / Forward)
- [x] Player lunge animation on combo land
- [x] Body part damage system — HP + status per part (HEALTHY/BRUISED/BROKEN/DISABLED)
- [x] Body highlight — colored zones, positioned above End Turn button
- [x] Combat log — small, upper-left, color-coded
- [x] Kickboxer character image in character select and battle scenes
- [x] Enemy plans random target part; shown in intent label
- [x] Stun effect — enemy skips next attack
- [x] Arm damage reduces enemy intent_damage (only on status change)
- [x] Sub-part damage system — jaw/brain/ribs/lung/heart/spine/elbow/wrist/kneecap/thigh
- [x] Fatal organ system — Heart (binary), Brain (3HP), Spine (2HP); win/loss via organ destruction; no HP bars
- [x] Limb penalty system — attack damage scaled by attacking limb status; guard block fails/doubled chip on damaged limbs
- [x] Player body part + sub-part damage — mirrors enemy; rolls on unguarded hits
- [x] Player sub-part effects: jaw, concussion, ribs, lung, heart, spine, elbow, wrist, kneecap, stagger
- [x] Status effect labels above player character (JAW / DIZZY / RIBS / LUNG / ELBOW / WRIST / KNEE / STAGGER)
- [x] Both body selectors with hover tooltips
- [x] Player body highlight — same visual style as enemy selector

## Planned / TODO
- [ ] Enemy status effect labels above enemy character (STUN / JAW / etc.)
- [ ] Streamer character implementation
- [ ] Multiple enemy types
- [ ] Win/loss screen polish
- [ ] Main menu and character select text cleanup
- [ ] Sound effects and music
- [ ] Run structure (map, rewards, progression)
