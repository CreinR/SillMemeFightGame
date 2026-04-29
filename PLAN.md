# SillMemeFightGame — Design Plan

## Overview
A turn-based card fighting game built in Godot 4. Two characters fight on a 6-slot battlefield. Each turn has three phases: Move, Attack, and Defense.

---

## Characters

### Kickboxer (active)
- HP: 80 | Energy: n/a
- Deck: fixed hands per phase (Kick, Jab, Hook, Uppercut, Knee)
- Character image: `assets/cards/Kickbokser.png`

### Streamer (disabled — coming soon)
- HP: 65 | Energy: 4
- Deck: Arrows, Shield, Gun combo chain

---

## Turn Structure

### Phase 1: Move
Cards: Back / Stance / Forward
- Back moves the player one slot away from the enemy
- Forward moves the player one slot toward the enemy
- Stance stays in place (free, cost 0)
- No button — playing any card advances to phase 2

### Phase 2: Attack
Cards: Kick / Jab / Hook / Uppercut / Knee
1. Select an attack card → it floats above the hand; only valid target zones light up on the enemy body
2. Click a different attack card to swap selection (previous card is deselected automatically)
3. Click a lit zone on the enemy → combo executes (e.g. Kick + Hoofd = Head Kick) and player lunges
4. Invalid zones are greyed out and non-clickable
- "Skip →" button skips the attack phase

### Phase 3: Defense
Cards: Guard Head / Guard Chest / Guard Legs / Guard Feet
1. Click a guard card → it floats above the hand with a blue highlight
2. Only the matching body part on the player body highlight lights up; all others grey out
3. Click the lit zone on the player body highlight → guard is set, turn ends immediately
4. Clicking a different guard card swaps the selection (same as attack re-selection)
- If the enemy attacks the guarded part: 0 damage and no sub-part rolls; wrong part → full damage + sub-part rolls
- Intent label shows which part the enemy will target (e.g. "Attack: 10 → Head")
- "End Turn" button skips defense entirely

---

## Combat Mechanics

### Range
Each attack has a min/max range. Out-of-range cards are grayed out and unselectable.

| Card      | Range |
|-----------|-------|
| Jab       | 2     |
| Hook      | 1     |
| Uppercut  | 1     |
| Knee      | 1     |
| Kick      | 2     |

### Body Part Combos

| Card     | Head                  | Chest          | Legs               | Feet         |
|----------|-----------------------|----------------|--------------------|--------------|
| Jab      | Head Jab (5)          | Body Jab (4)   | Low Jab (3)        | Foot Jab (3) |
| Hook     | Left Hook (12 + stun) | Body Hook (10) | —                  | —            |
| Kick     | Head Kick (10 + stun) | Middle Kick (8)| Low Kick (6 + weak)| Sweep (4 + stun) |
| Uppercut | KO Uppercut (14 + stun)| Body Uppercut (8)| —               | —            |
| Knee     | —                     | Body Knee (9)  | Leg Knee (7 + weak)| —            |

### Fatal Organ System
Win/loss is determined entirely by fatal organ destruction — no global HP bars.

**Fatal organs (both player and enemy):**
| Organ | Location | Type | HP | Base chance | Win/loss trigger |
|-------|----------|------|----|-------------|-----------------|
| Hart (Heart) | borst | Binary | 1 | 8% | Instant death on first hit |
| Hersenen (Brain) | hoofd | Degrading | 3 | 15% | Death at 0 HP |
| Wervelkolom (Spine) | borst | Degrading | 2 | 12% | Death at 0 HP |

Brain stages: HEALTHY(3) → CONCUSSED(2) → CRITICAL(1) → DESTROYED(0)
Spine stages: HEALTHY(2) → COMPRESSED(1) → DESTROYED(0)

Brain damage also applies concussion effect (random attack forced).

**Danger indicators:**
- Body highlight zones for hoofd/borst pulse red when they contain a damaged fatal organ
- Warning logged at turn start: CONCUSSED → yellow warning; CRITICAL → red every turn
- Brain hit log: "Brain rattled! [X HP remaining]"; fatal: death message in red
- Heart has no warning — binary instant

**Non-fatal organs unchanged:** Jaw, Ribs, Lung, Elbow, Wrist, Kneecap, Thigh

### Body Part Damage System
Each enemy body part has its own HP and progresses through four statuses:

| Status   | HP threshold | Visualisation       |
|----------|-------------|---------------------|
| HEALTHY  | > 50%       | Green               |
| BRUISED  | 25–50%      | Yellow              |
| BROKEN   | > 0%        | Orange              |
| DISABLED | 0           | Red                 |

Body parts and their HP:
- `hoofd` (head): 15 HP
- `borst` (chest): 30 HP
- `linkerarm` / `rechterarm` (arms): 20 HP each
- `linkerbeen` (left leg): 20 HP
- `rechterbeen` (right leg): 20 HP

All naming is unified — cards, body highlight zones, and body_parts all use the same keys.

Hitting an arm reduces `intent_damage` only when the arm's status changes (HEALTHY→BRUISED→BROKEN→DISABLED).

The player has the same body part structure. Enemy attacks target the player body part shown in the intent label. If the player guarded that part correctly → 0 damage and no sub-part rolls; otherwise damage applies and sub-parts roll.

### Sub-Part System
Each body part contains sub-parts that can be hit when the parent part takes damage. Sub-parts have binary HP (1 hit = destroyed) and a base chance that scales with the parent part's status:

| Parent Status | Chance multiplier |
|---------------|-------------------|
| HEALTHY       | 1.0×              |
| BRUISED       | 1.5×              |
| BROKEN        | 2.5×              |
| DISABLED      | 0 (no rolls)      |

Sub-parts per body part (effects listed as enemy / player):

| Parent              | Sub-part   | Chance | Enemy effect                          | Player effect                          |
|---------------------|------------|--------|---------------------------------------|----------------------------------------|
| hoofd               | Kaak       | 40%    | skip 1 attack turn                    | skip 1 attack phase                    |
| hoofd               | Hersenen   | 15%    | random target for 2 turns             | random attack card forced for 2 turns  |
| borst               | Ribben     | 50%    | 1 self-damage per attack              | 1 self-damage per attack card played   |
| borst               | Long       | 25%    | -3 damage for 2 turns                 | draw 1 fewer card for 2 turns          |
| borst               | Hart       | 8%     | stun + instant -5 HP                  | skip attack + instant -5 HP            |
| linkerarm/rechterarm| Elleboog   | 30%    | -2 damage on next attack              | -2 damage on next attack               |
| linkerarm/rechterarm| Pols       | 25%    | 50% miss on next attack               | 50% miss on next attack                |
| bovenbenen/voeten   | Knieschijf | 35%    | reserved (enemy stationary)           | can't use Forward/Back for 2 turns     |
| bovenbenen/voeten   | Dijbeen    | 30%    | -2 intent_damage (permanent)          | reserved (future)                      |

Sub-part hit messages appear yellow in the combat log.

### Status Effects
| Effect | Description |
|--------|-------------|
| Stun   | Enemy skips next turn and picks a new target |
| Weaken | Reduces enemy's next attack by a fixed amount |

### Limb Penalty System

**Attack penalties** — before resolving, check the status of the attacking limb:
| Limb status | Damage multiplier |
|-------------|------------------|
| HEALTHY     | 1.0× (no penalty) |
| BRUISED     | 0.85×             |
| BROKEN      | 0.6×              |
| DISABLED    | 0.4× (pushes through pain) |

Attack limb mapping: Jab → linkerarm, Hook → rechterarm, Uppercut → rechterarm, Knee → linkerbeen, Kick → rechterbeen

If a penalty applies → gray log: "Your [limb] is [status] — [combo name] deals reduced damage."

**Defense penalties** — when a guard is confirmed, check the required limbs:
- Any required limb DISABLED → block fails entirely, full damage + sub-part rolls, red log warning
- Any required limb BRUISED/BROKEN → block succeeds, chip damage doubled, yellow log warning

Guard limb requirements: Guard Head → both arms, Guard Chest → left arm, Guard Left Leg → left leg, Guard Right Leg → right leg

**Card visual feedback:**
- Attack card with BRUISED/BROKEN limb → orange `!` indicator
- Attack card with DISABLED limb → red `!` indicator
- Guard card with DISABLED required limb → semi-transparent overlay + red "DISABLED" label (still selectable)

### Defense
Binary block: guard the correct body part → 0 damage to main HP, but chip damage applies to the guarding limb. Wrong part → full damage + sub-part rolls.

**Chip damage on block**: `ceili(intent_damage × 0.2)` applied to the guarding limb HP on a successful block.
- Guard Head → left arm absorbs chip
- Guard Chest → right arm absorbs chip
- Guard Legs → left leg absorbs chip
- Guard Feet → right leg absorbs chip

Chip triggers limb status changes and sub-part rolls normally. If the limb is DISABLED, chip goes to player HP instead with a red warning log. Playing any guard card ends the turn immediately.

---

## Enemy AI
- Stationary — fixed at slot 4 on the battlefield
- Picks a random target body part at game start and after each attack
- Targets all 6 body parts: hoofd, borst, linkerarm, rechterarm, linkerbeen, rechterbeen
- Intent shown as "Attack: X → BodyPart" so the player can guard correctly
- Stun causes it to skip its turn and pick a new target

---

## Battlefield
- 6 slots (positions 0–5)
- Player starts at slot 2, enemy fixed at slot 4 (distance 2 — immediately in range for Jab and Kick)
- Player character animates with a lunge when a combo lands

---

## UI Layout
- **Top-left**: Combat log (small, color-coded, 5 lines max)
- **Top-right**: Enemy HP bar + intent label ("Attack: X → Part")
- **Middle**: Battlefield (6 slots with character sprites)
- **Left column (mid-lower)**: Player body highlight — colored zones showing player body part health; flashes red on hit; same visual style as enemy selector
- **Right column (mid-lower)**: Enemy body highlight — colored zones showing enemy body part health; valid targets glow on attack select, others grey out
- **Bottom-left**: Player HP bar + player panel (compact)
- **Bottom-right**: Phase label + End Turn / Skip button (compact, at screen bottom)
- **Bottom-center**: Card hand

Both body selectors sit at the same screen height (`y=500`), above their respective panels.

### Combat Log Colors
- Red `(1, 0.4, 0.4)` — player attack hits
- Yellow `(1, 0.8, 0.2)` — body part status changes (bruised / broken / disabled)
- Blue `(0.4, 0.7, 1)` — enemy actions
- Gray `(0.8, 0.8, 0.8)` — info messages

---

## Completed
- [x] 3-phase turn system (Move / Attack / Defense)
- [x] Kickboxer character with full fixed hand per phase
- [x] Two-step attack: select attack card → click body zone on enemy
- [x] Body part combos with stun / weaken effects
- [x] Valid zones highlight on attack select; invalid zones grey out
- [x] Two-step defense: select guard card (blue float) → click matching body zone → turn ends
- [x] Guard card re-selection mirrors attack re-selection; player body highlight dims non-valid parts
- [x] Range system — out-of-range cards grayed out
- [x] Battlefield movement (Back / Stance / Forward)
- [x] Player lunge animation on combo land
- [x] Body part damage system — HP + status per part (HEALTHY/BRUISED/BROKEN/DISABLED)
- [x] Body highlight — colored zones on right panel, positioned above Skip button
- [x] Body part selector — click colored zones to target
- [x] Combat log — small, upper-left, color-coded
- [x] Kickboxer character image in character select and battle scenes
- [x] Enemy picks random target part each turn; shown in intent label
- [x] Stun effect — enemy skips turn
- [x] Arm damage reduces enemy intent_damage (only on status change)
- [x] Enemy HP bar uses dynamic max_hp
- [x] Sub-part damage system — per-part sub-parts with chance rolls, status multipliers, and effects (jaw/concussion/ribs/lung/heart/elbow/wrist/thigh)
- [x] Attack card re-selection — clicking a different attack card swaps the pending selection
- [x] CostBadge removed from card UI
- [x] Unified body part naming — cards, highlight zones, and enemy body_parts all use `hoofd`/`borst`/`linkerarm`/`rechterarm`/`bovenbenen`/`voeten`
- [x] Player body part + sub-part damage system — mirrors enemy; rolls on unguarded hits
- [x] Player sub-part effects: jaw (skip attack), concussion (forced random card), ribs (self-damage), lung (draw penalty), heart (skip+HP), elbow (damage debuff), wrist (miss), kneecap (movement blocked)
- [x] Status effect labels above player character (JAW / DIZZY / RIBS / LUNG / ELBOW / WRIST / KNEE)
- [x] Player character sprite shows body part health colours (green→yellow→orange→red)
- [x] Player body highlight — same visual style as enemy selector, positioned left column at same screen height
- [x] Both body selectors aligned at y=500, above player panel and End Turn button
- [x] Player panel and End Turn button moved to screen bottom and made compact
- [x] Limb chip damage on block — ceili(20%) to guarding limb; DISABLED limb → chip to player HP with red warning
- [x] Limb penalty system — attack damage scaled by attacking limb status; guard block fails/doubled chip on damaged limbs; card visual warnings
- [x] Fatal organ system — Heart (binary), Brain (3HP degrading), Spine (2HP degrading); win/loss via organ destruction; HP bars removed; body highlight danger zones

## Completed
- [x] Body highlight hover tooltips — hover any zone (player or enemy) to see sub-part statuses; 0.2s delay, auto-positioned left/right of zone, colour-coded (red=HIT/DESTROYED, orange=degraded fatal organ, dim=intact)

## Planned / TODO
- [ ] Enemy status effect labels above enemy character (STUN / JAW / etc.)
- [ ] Streamer character implementation
- [ ] Multiple enemy types
- [ ] Win/loss screen polish
- [ ] Main menu and character select text cleanup
- [ ] Sound effects and music
- [ ] More combo cards and status effects
- [ ] Run structure (map, rewards, progression)
