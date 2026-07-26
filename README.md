# CoA Inspect Tree

**See any player's full Character Advancement tree when you inspect them.**
Built by **WoloUI** for Project Ascension (WoW 3.3.5a).

On a classless server, "what class is that guy" is the wrong question — the real question is
*what did they actually build*. Ascension's inspect window shows you gear. It does not show
you the tree. CoA Inspect Tree draws the full Character Advancement grid of whoever you
inspect, right next to the inspect frame, with every learned node lit up and ranked.

---

## Features

- **Full talent grid, not just talents.** Reads the complete tree from
  `C_CharacterAdvancement.GetEntriesByClass` per tab, which returns *every* entry —
  talents **and** the ability nodes in the grid. (Using `GetTalentsByClass` alone silently
  drops the ability nodes: roughly a dozen learned nodes would show up with no home on the
  grid.) Falls back to `GetTalentsByClass` when the richer API isn't available.
- **Learned nodes lit, unlearned dimmed.** Learned nodes get a coloured accent ring matching
  the tree's own colour scheme; empty sockets go desaturated and grey.
- **Ranks on every node** as `rank/maxRank`, and the number turns gold when the node is
  maxed.
- **Real spell tooltips on hover** — the genuine in-game tooltip via
  `GameTooltip:SetHyperlink`, resolved to the spell of the rank they actually have, plus the
  rank line and the tab name. Falls back to the node name if the spell can't be resolved.
- **Connection lines** between nodes, drawn as elbow connectors so prerequisite paths are
  readable on a grid.
- **Choice nodes handled properly.** Nodes offering 2+ options share a grid cell. Drawing
  them stacked meant the dimmed *unlearned* option covered the learned one, so learned
  choices looked like they "never lit up". Now exactly one option is drawn per cell: the
  learned one when there is one, otherwise the lowest ID (deterministic, not dependent on
  `pairs` order).
- **Spec selector built into the panel.** Buttons for each unlocked spec on the inspected
  player; clicking re-queries that spec's tree. Only the relevant tab pair is shown — the
  Class tab on the left, the spec they actually have talents in on the right — never all
  specs at once.
- **Compare button.** Toggle your own tree in alongside theirs, so you can read the
  difference directly instead of alt-tabbing between screenshots. Your own ranks are read
  via `UnitTalentRankByID("player", …)`, because `GetInspectedBuild` doesn't report ranks
  for yourself.
- **Adjustable panel scale** — `-` / `+` / `Reset`, from 50% to 150%, persisted per
  character. (Deliberately discrete buttons and not a slider: a slider that is a child of
  the frame it scales rescales itself under your cursor mid-drag and jams.)
- **Follows your target.** Retargeting discards the previous player's tree and requests the
  new one; the panel hides itself when the inspect window closes.
- **Doesn't open itself.** In CoA, `INSPECT_CHARACTER_ADVANCEMENT_RESULT` fires whenever
  *anything* inspects your target — including other addons doing it automatically in
  combat. The panel is gated on an actually-visible inspect frame, so it never pops open on
  its own mid-fight.
- **Works with both stock and Ascension-modded inspect frames** (`AscensionInspectFrame` and
  `InspectFrame`), and silently disables itself on realms with no Character Advancement API.
- **Retries while data loads** — up to 5 attempts at 0.5s, showing "Loading talents…" rather
  than an empty grid (3.3.5 has no `C_Timer`, so this is a one-shot `OnUpdate` frame).

---

## Installation

1. Extract the `CoAInspectTree` folder into `Interface/AddOns/`.
2. Restart the game client.
3. Target a player, inspect them, and the tree appears next to the inspect window.

Requires a realm with Ascension's Character Advancement API. On login the addon prints
`active (Character Advancement detected)` when it's live; if you see nothing, the realm
doesn't expose it.

## Commands

Diagnostics, all printing to chat:

| Command | Does |
|---|---|
| `/coait` | Summary of the current target's tree, per tab |
| `/coait class` | Every node in the Class tab with grid positions |
| `/coait specs` | Active and unlocked specs of the inspected player |
| `/coait choice` | Choice nodes: cell overlap and which option is known |
| `/coait miss` | Learned nodes that aren't present in the built tree |
| `/coait entries` | Raw entries returned per tab |
| `/coait findmiss` | Hunts for nodes missing from the grid |
| `/coait cats` | Category dump |
| `/coait api` | Which Character Advancement API functions exist on this realm |

## Credits

Made by **WoloUI**.
