# Windfury

Windfury celebrations for shamans on the **World of Warcraft Forever client** (Interface `16001`). Extracted from Fishmonger into an independent addon: no Fishmonger, Auctionator, service, account, or external library required.

## Install

1. [Download Windfury-1.0.1.zip](https://github.com/GuppitusMaximus/windfury/releases/latest/download/Windfury-1.0.1.zip) from Releases.
2. Fully quit WoW, then extract the ZIP into `_forever_/Interface/AddOns/`.
3. Check that the path is `AddOns/Windfury/Windfury.toc`, without an extra enclosing folder.
4. Start WoW, enable **Windfury** in the AddOns list, and type `/wf test`.

Use the release ZIP for installation. GitHub's source ZIP contains development files; if using that, copy only its `Windfury` folder into AddOns. Fully restart after installing new sounds or textures; `/reload` may not discover them.

If you also use Fishmonger, run `/fm wf off` to disable its built-in celebration and avoid duplicate effects. Windfury has its own settings and does not change or import Fishmonger's saved data.

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
