# ShambaGamba WindFury Proc

Windfury celebrations for shamans on the **World of Warcraft Forever client** (Interface `16001`). Extracted from Fishmonger into an independent addon: no Fishmonger, Auctionator, service, account, or external library required.

## Installation

**Supported client:** World of Warcraft Forever (`_forever_`, Interface `16001`). Automatic proc celebrations are for shamans. This release is not intended for Retail or other Classic clients.

1. [Download the latest release](https://github.com/GuppitusMaximus/windfury/releases/latest) and select **ShambaGamba-WindFury-Proc-1.0.2.zip** under **Assets**. Use the addon ZIP, rather than GitHub's automatically generated source archives.
2. Fully quit WoW.
3. Open your WoW installation folder, then `_forever_/Interface/AddOns/`. If needed, create the `AddOns` folder.
4. Extract the ZIP and place its **Windfury** folder directly inside `AddOns`.
5. Start WoW and enable **ShambaGamba WindFury Proc** in the character selection screen's AddOns list.
6. Log in, type `/wf` to open settings, then `/wf test` to preview your selected effects.

The installed files should look like this:

```text
World of Warcraft/
└── _forever_/
    └── Interface/
        └── AddOns/
            └── Windfury/
                ├── Windfury.toc
                ├── Core.lua
                ├── Windfury.lua
                ├── Art/
                └── Sounds/
```

The internal folder stays **Windfury** so upgrades retain existing settings. Do not rename it or nest it inside another folder. No Fishmonger installation is required.

### Upgrading or using Fishmonger alongside it

Quit WoW and replace the existing `AddOns/Windfury` folder with the one from the new ZIP. Keep your `WTF` folder: it contains saved settings. Your existing sound choices and effect toggles are preserved when upgrading.

If you also use Fishmonger, run `/fm wf off` to disable its built-in celebration and avoid duplicate effects. This standalone addon has its own settings and does not change or import Fishmonger's saved data.

### First run and troubleshooting

- New installs use **Windfury storm** with **Original deep hit**. Slot reels and the large WINDFURY text start **off**. Open `/wf` to enable them if desired.
- `/wf test` previews the selected effects, even when automatic celebrations are disabled. `/wf on` enables automatic celebrations.
- If the addon is missing from the AddOns list, check the folder structure above and ensure you installed it for the correct client.
- If sounds or artwork are missing, fully quit and reopen WoW; `/reload` may not discover new files. Sounds use the game's Master channel, so check that game sound is enabled and audible.
- If the preview works but combat does not trigger it, check `/wf status`, that your character is a shaman, and that you are using the supported Forever client. See the detection limitations below.

## Features

- Animated goblin slot reels with gold coins and draggable placement.
- Three hit sound choices and five jackpots, each with five loudness levels.
- Three rapid impacts per celebration, plus an immediate jackpot sound.
- Optional large WINDFURY text, gold flash, scrolling combat text, and a brief floating-number size increase with restoration.
- Experimental nearby hit amounts on the reels.
- Independent toggles and settings saved between sessions.

New installations default to **Windfury storm** and **Original deep hit**, with slot reels and the large WINDFURY text disabled. Existing saved choices are preserved. Enable these visual effects in `/wf` whenever you like.

## Commands

| Command | Action |
| --- | --- |
| `/wf` or `/windfury` | Open settings |
| `/wf test` | Preview chosen effects, including while disabled |
| `/wf move` | Toggle dragging / locking the reels |
| `/wf on` / `/wf off` | Enable / disable automatic celebrations |
| `/wf status` | Show state and session celebration count |
| `/wf help` | Show command help |

## Compatibility and limitations

Automatic detection uses the `SPELL_UPDATE_COOLDOWN` signal for spell `439440`, with zero cooldown categories, observed on Forever 1.60.1.70938. It listens automatically only for shamans. Other WoW clients are **not supported by this release**; changing the TOC interface number does not establish compatibility. Party attribution and completeness across all combat scenarios have not been fully validated.

Experimental hit amounts are timing-based nearby physical hits, not confirmed personal Windfury damage. They may include another player's hits. Busy bursts, target changes, and casts can suppress them. Switch **Experimental hit numbers** off to use icons instead. Amounts are never saved.

The floating-number pulse briefly changes all world text, including other damage and healing. It restores the previous scale when possible and does not overwrite a setting changed elsewhere. Each effect can be disabled in settings. Sounds use the game's Master channel.

Settings and bounded diagnostic records are stored locally in `WindfuryDB`. The addon contains no networking, remote sync, auction scanning, or account configuration.

## Development

Run `luajit tests/smoke.lua` from the repository root. This mocked-client check covers independent initialization, settings construction, command behavior, proc filtering, animation construction, and all sound selections. It does not replace in-game verification of rendering, audio, or live proc attribution.

Run `python3 tools/package.py` to create the install ZIP and SHA-256 checksum in `dist/`.

The initial extraction preserves the Windfury implementation and current media from Fishmonger 0.59.3. No private repository history or player data is included.
