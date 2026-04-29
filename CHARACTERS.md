# SillMemeFightGame — Characters

## Kickboxer (active)

- Energy: n/a
- Deck: full attack roster available every turn (Jab, Hook, Uppercut, Overhand, Backfist, Roundhouse Kick, Front Kick, Spinning Heel Kick)
- Character image: `assets/cards/Kickbokser.png`

### Kickboxer — Body Part Stats

| Body Part | Durability | HP (base×D) | Toughness | Power | Speed |
|-----------|-----------|-------------|-----------|-------|-------|
| Hoofd | 0.8 | 12 | 0.7 | — | — |
| Borst | 1.2 | 36 | 1.3 | — | — |
| Linkerarm | 1.0 | 20 | 1.0 | 1.0 | 1.3 |
| Rechterarm | 1.0 | 20 | 1.0 | 1.2 | 1.0 |
| Bovenbenen | 1.2 | 24 | 1.0 | 1.0 | 1.1 |
| Voeten | 1.2 | 24 | 1.0 | 1.3 | 0.8 |

*Durability low on Hoofd → brittle head. Borst very tough (1.2 dur, 1.3 tough). Voeten deal high damage (P 1.3) but Spinning Heel Kick misfires more often (Speed 0.8 → 25% base miss). Rechterarm carries extra punch (P 1.2). Linkerarm is fast and reliable (Speed 1.3).*

<!-- Streamer: planned for future implementation; full redesign needed for new combat system -->

---

## Default Enemy — Body Part Stats

| Body Part | Durability | HP (base×D) | Toughness | Power | Speed |
|-----------|-----------|-------------|-----------|-------|-------|
| Hoofd | 1.2 | 18 | 1.1 | — | — |
| Borst | 0.8 | 24 | 0.7 | — | — |
| Linkerarm | 1.0 | 20 | 1.0 | 0.8 | 0.8 |
| Rechterarm | 1.0 | 20 | 1.0 | 1.3 | 1.1 |
| Bovenbenen | 0.8 | 16 | 0.8 | 1.0 | 1.2 |
| Voeten | 0.8 | 16 | 0.8 | 1.1 | 1.0 |

*Strong head (D 1.2, T 1.1) but fragile chest (D 0.8, T 0.7 → sub-parts easy to hit). Rechterarm is the power arm (P 1.3). Linkerarm is weak (P 0.8, Speed 0.8). Legs are fragile (D 0.8, T 0.8).*

---

## Body Part Base HP Values

| Body part | Base HP | Note |
|-----------|---------|------|
| hoofd (head) | 15 | scaled by Durability stat |
| borst (chest) | 30 | scaled by Durability stat |
| linkerarm (left arm) | 20 | scaled by Durability stat |
| rechterarm (right arm) | 20 | scaled by Durability stat |
| bovenbenen (upper legs) | 20 | scaled by Durability stat |
| voeten (feet) | 20 | scaled by Durability stat |

---

## Attack Card → Attacking Limb Mapping

| Card | Attacking Limb |
|------|---------------|
| Jab | linkerarm |
| Hook | rechterarm |
| Uppercut | rechterarm |
| Overhand | rechterarm |
| Backfist | linkerarm |
| Roundhouse Kick | voeten |
| Front Kick | bovenbenen |
| Spinning Heel Kick | voeten |

---

## Guard Card → Required Limb Mapping

| Guard | Required Limb(s) | Chip absorber |
|-------|-----------------|---------------|
| Guard Head | linkerarm + rechterarm | linkerarm absorbs chip |
| Guard Chest | linkerarm | rechterarm absorbs chip |
| Guard Upper Legs | bovenbenen | bovenbenen absorbs chip |
| Guard Feet | voeten | voeten absorbs chip |
