# SillMemeFightGame — Index

## Overview
A turn-based card fighting game built in Godot 4. Two characters fight on a 6-slot battlefield. Each turn both sides simultaneously choose 1 movement, 1 attack, 1 defense in any order.

## Files
- [COMBAT.md](COMBAT.md)       — turn system, range, body parts, sub-parts, organs, status effects, defense, AI
- [UI.md](UI.md)           — layout, colors, tooltips, card tabs, action tracker, body selector
- [CHARACTERS.md](CHARACTERS.md)   — characters, stats, limbs, guard/attack mappings, body part HP
- [ATTACKS.md](ATTACKS.md)      — full attack roster, combo table, special effect descriptions

## Completed
- [x] Simultaneous free-order turn system (Move / Attack / Guard planned together, resolved at once)
- [x] Action tracker UI above hand — fills in as actions chosen, ✓ checkmark on used card
- [x] 3-section card hand — Movement left, Attack center, Guard right; section greys out when action used
- [x] End Turn button always visible — skips remaining unused actions
- [x] Full attack roster: Jab, Hook, Uppercut, Overhand, Backfist, Roundhouse Kick, Front Kick, Spinning Heel Kick
- [x] Overhand 50% guard bypass
- [x] Backfist brain boost (+0.15 brain sub-part chance)
- [x] Front Kick push (enemy pushed 1 slot back after hit)
- [x] Spinning Heel Kick miss stagger (blocks movement next turn)
- [x] Enemy mobile — plans movement, attack, and guard simultaneously with player
- [x] Enemy guard system — enemy secretly guards a random part; chip damage on block
- [x] Body part renaming — bovenbenen (upper legs) and voeten (feet)
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
- [x] Fatal organ system — Heart (binary), Brain (3HP), Spine (2HP); win/loss via organ destruction
- [x] Limb penalty system — attack damage scaled by attacking limb status; guard block fails/doubled chip on damaged limbs
- [x] Player body part + sub-part damage — mirrors enemy; rolls on unguarded hits
- [x] Player sub-part effects: jaw, concussion, ribs, lung, heart, spine, elbow, wrist, kneecap, stagger
- [x] Status effect labels above player character (JAW / DIZZY / RIBS / LUNG / ELBOW / WRIST / KNEE / STAGGER)
- [x] Both body selectors with hover tooltips
- [x] Player body highlight — same visual style as enemy selector

## TODO
- [ ] Enemy status effect labels above enemy character (STUN / JAW / etc.)
- [ ] Streamer character — full redesign needed for new combat system
- [ ] Multiple enemy types
- [ ] Win/loss screen polish
- [ ] Main menu and character select text cleanup
- [ ] Sound effects and music
- [ ] Run structure (map, rewards, progression)
