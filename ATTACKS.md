# SillMemeFightGame — Attack Roster

## Full Attack Roster (Kickboxer)

| Card | Limb | Range | Targets & Damage | Special |
|------|------|-------|-----------------|---------|
| **Jab** | linkerarm | 2–3 | hoofd 6, borst 5 | — |
| **Hook** | rechterarm | 1 | hoofd 12+stun, borst 10 | stun on hoofd |
| **Uppercut** | rechterarm | 1 | hoofd 14+stun, borst 8 | stun on hoofd |
| **Overhand** | rechterarm | 1–2 | hoofd 10 | 50% bypass enemy guard |
| **Backfist** | linkerarm | 2–3 | hoofd 8 | brain sub-part base chance +0.15 for this attack |
| **Roundhouse Kick** | voeten | 2–3 | hoofd 10+stun, borst 8, bovenbenen 6+weaken, voeten 4+stun | weaken on bovenbenen |
| **Front Kick** | bovenbenen | 2–3 | borst 7, bovenbenen 6 | pushes enemy back 1 slot after hit |
| **Spinning Heel Kick** | voeten | 3–4 | hoofd 16+stun | if miss → player stagger_turns=1 (no movement next turn) |

---

## Body Part Combo Effects

| Target | Status Effect | Condition |
|--------|--------------|-----------|
| hoofd | Stun | Hook, Uppercut, Roundhouse Kick, Spinning Heel Kick |
| bovenbenen | Weaken | Roundhouse Kick |

---

## Special Effect Descriptions

### Overhand — Guard Bypass
- 50% chance to bypass enemy guard on hoofd
- Log red: *"Overhand crashes through the guard!"*

### Backfist — Brain Boost
- Adds +0.15 to brain sub-part base hit chance for this single attack
- Log: *"The backfist rattles the skull directly!"*

### Front Kick — Push
- After a successful hit, enemy is pushed back 1 slot
- Log gray: *"Enemy stumbles back!"*

### Spinning Heel Kick — Miss Stagger
- If the attack misses (due to range or dodge), player receives stagger_turns=1
- Player cannot use movement cards next turn
- Log red: *"Missed the spinning heel kick — you stumble!"*
