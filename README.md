# SimpleLust
Simple lust tracker addon for wow. Based on old addons before the purge.

## Three States
<img width="187" height="62" alt="image" src="https://github.com/user-attachments/assets/b5a78e9c-6e44-49bb-affd-416a871728e0" />
<img width="225" height="56" alt="image" src="https://github.com/user-attachments/assets/e60e0926-5ef9-4b91-bcff-4d5a40d43540" />
<img width="206" height="57" alt="image" src="https://github.com/user-attachments/assets/35245e34-1800-4dfd-bce3-50b166adb088" />

## Positioning
Open WoW's Edit Mode and drag the SimpleLust frame to reposition it. Positions are saved separately for each Edit Mode layout when you save the layout. Reverting Edit Mode changes also restores the previous SimpleLust position.

## Settings
Select SimpleLust in Edit Mode to open its configuration panel. Settings are organized into collapsible sections:

- **General** controls whether the tracker is hidden while out of combat.
- **Wording** switches between the built-in Lust (default), Heroism, and Basic message sets.
- **Appearance** controls the font, size, and color of the Active, Cooldown, and Ready states independently.

Settings are saved separately for each Edit Mode layout.

## Third-party libraries
SimpleLust requires [FerrozEditModeLib](https://www.curseforge.com/wow/addons/ferrozeditmodelib) 1.1.20 or newer for Edit Mode positioning and layout persistence.

## Known issues
The in-combat Lust buff timer still uses the exhaustion debuff as a fallback when the buff aura is unavailable.
