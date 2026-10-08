# SimpleLust

A minimal World of Warcraft tracker for Bloodlust, Heroism, and equivalent effects.

## Display States

- **Active** — shows the estimated remaining buff duration.
- **Cooldown** — shows the remaining exhaustion duration.
- **Ready** — shows when the effect can be used.

## Edit Mode

Open WoW Edit Mode and select SimpleLust to:

- Move the tracker.
- Hide it while out of combat.
- Choose Lust, Heroism, or Basic wording.
- Set the font, size, and color for each display state.

Position and settings are saved per Edit Mode layout.

## Dependency

Requires [FerrozEditModeLib](https://www.curseforge.com/wow/addons/ferrozeditmodelib) 1.1.20 or newer.

## Tracking Limitation

WoW does not consistently expose the active Lust buff duration to SimpleLust during combat. When the buff is unavailable, SimpleLust estimates the remaining 40-second active duration from the 10-minute exhaustion debuff:

```text
active time remaining = exhaustion time remaining - 9:20
```

The tracker uses the actual buff duration whenever WoW provides it; otherwise it uses this calculation.
