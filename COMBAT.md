# SillMemeFightGame — Combat Mechanics

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

### Combat Log During Resolution
- Gray: `"--- Turn resolving ---"`
- Gray: `"Both fighters move."` (if any movement)
- Attack and defense messages follow as normal

---

## Range System

Each attack card has `min_range` / `max_range` in slots of distance between player and enemy. Out-of-range attack cards are grayed out and unselectable during planning. Range is rechecked after movement during resolution — attack misses if now out of range.

---

## Battlefield

- 6 slots (positions 0–5)
- Player starts at slot 2, enemy starts at slot 4 (distance 2 — in range for Jab/Backfist/Roundhouse/Front Kick)
- Both characters animate movement with smooth tweens; player lunges on combo land

---

## Body Part Damage System

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

---

## Sub-Part System

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

---

## Fatal Organ System

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

---

## Status Effects

| Effect | Description |
|--------|-------------|
| Stun | Enemy skips next attack; picks a new target |
| Weaken | Reduces enemy's intent_damage by `value` |
| Stagger | Player cannot use movement cards next turn (Spinning Heel miss) |

---

## Defense Mechanics

### Guard & Chip Damage
Binary block: guard the correct part → 0 damage to body, but chip damage `ceili(intent_damage × 0.2)` applies to the guarding limb:
- Guard Head → linkerarm absorbs chip
- Guard Chest → rechterarm absorbs chip
- Guard Upper Legs → bovenbenen absorbs chip
- Guard Feet → voeten absorbs chip

If the limb is DISABLED, chip goes to the body part directly. Chip triggers limb status changes and sub-part rolls normally.

### Defense Resolution Detail
- Player guard: click a guard card → immediately locked in; no body zone click needed
- Enemy guard: secretly chosen random body part at turn start
- If guard matches incoming attack part → block; chip damage `ceili(dmg × 0.2)` applied to guarding limb
- If guarding limb is DISABLED → block fails; full damage goes through (red warning)
- If guarding limb is BRUISED/BROKEN → block succeeds, chip damage doubled (yellow warning)
- If both sides guarded correctly → both blocks succeed independently

---

## Attack Limb Penalties

Before resolving, check the attacking limb's status:

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

**Card visual feedback:**
- Attack card with BRUISED/BROKEN limb → orange `!` indicator
- Attack card with DISABLED limb → red `!` indicator
- Guard card with DISABLED required limb → semi-transparent overlay + red "DISABLED" label

---

## Enemy AI

- Starts at slot 4; can move each turn (weighted toward closing to mid-range)
- Picks from full attack roster filtered by current range
- Intent label shows: `"Attack: X → BodyPart"` (attack + target only; movement and guard remain hidden)
- Stun causes it to skip attack and pick a new target
- Enemy stagger (from own Spinning Heel miss or kneecap sub-part hit) blocks movement for the stagger duration

---

## Character Stat System

Each character has four stats per body part, stored in `scripts/character_stats.gd` (`CharacterStats` resource). Stats scale from **0.5 to 1.5** with **1.0 as the neutral default**. Stat profiles are loaded in `battle.gd._ready()` via `player.apply_stats()` and `enemy.apply_stats()`.

### Stats and Their Effects

| Stat | Applies to | Formula | Effect |
|------|-----------|---------|--------|
| **Durability** | All parts | `final_hp = base_hp × durability` | Scales the body part's starting HP. Applied once at fight start. |
| **Toughness** | All parts | `final_chance = base_chance × status_mult × (1 / toughness)` | Higher toughness makes sub-parts harder to hit. Applied in `BodyPart.roll_sub_parts()`. |
| **Power** | Attacking limbs only | `final_dmg = base_dmg × status_mult × power` | Scales outgoing damage for attacks using that limb. Applied in `battle._apply_player_limb_penalty()` (player) and `enemy._plan_attack()` (enemy). |
| **Speed** | Attacking limbs only | `miss_chance = 0.2 × (1 / speed)` | Adds a random miss chance to Spinning Heel Kick. Lower speed → more likely to stumble. Applied in `battle._shk_speed_miss()`. |

### Notes
- Power and Speed are only present in the stats dictionary for limbs that attack (arms, legs). Head and chest have only Durability and Toughness.
- The `SHK_BASE_MISS` constant in `battle.gd` is set to `0.2` (20% base miss with Speed 1.0).
- Toughness applies a `1/toughness` multiplier on the rolled chance, so `toughness = 1.3` reduces sub-part hit chance by ~23%; `toughness = 0.7` increases it by ~43%.
- Stats are visible in the body part hover tooltip as a 5-block bar: `□□□□□` = 0.5, `■■■□□` = 1.0, `■■■■■` = 1.5.
