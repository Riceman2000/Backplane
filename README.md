# Backplane

Agentic hardware development. Claude Code, Codex and Grok work on your KiCad boards and FreeCAD parts, and every change they make is drawn live beside the conversation, in a browser, on your phone, or in the desktop app.

![A thread beside the board in 3D in the browser, and the same change compared on a phone](docs/media/hero.png)

## Why

- **Agents that know KiCad.** Each one is told the exact `kicad-cli` and the project's canonical files, and gets the [KiStack](https://github.com/American-Embedded/KiStack) skills: schematics, symbols, footprints, layout, BOM, Gerbers, panelizing and product renders, kept up to date.
- **You see what the agent changed.** A board file is text no one can review by reading it. Here the board, schematic and 3D model redraw as the agent saves, every step is kept, and any two versions compare like a diff.
- **Mechanical in the same loop.** Agents model enclosures and brackets in FreeCAD from the board's real outline and parts, and the Mech tab shows them in 3D beside the board.
- **Your machine, your tools.** It runs locally with your KiCad, your FreeCAD, your files and your agent subscriptions: Claude Code, Codex or Grok.
- **Away from the desk.** The browser and the phone apps reach it over Tailscale: follow a turn, answer its questions and review the board from anywhere.

## Web and phone, the same work

The hub runs on your machine. The browser and the native Android and iOS apps reach it over your tailnet and show the same threads, live: start a turn at your desk, then follow it, answer its questions and review the board from your phone. The phone apps are not a reduced view: threads, the board, schematic, 3D model, Mech parts, files and the design history with Compare are all there, drawn natively, with a notification when a turn ends or an agent needs you. Several machines show as one list.

| | | | |
|---|---|---|---|
| ![](docs/media/phone-list.png) | ![](docs/media/phone-thread.png) | ![](docs/media/phone-3d.png) | ![](docs/media/phone-mech.png) |

## What it does

**Viewers that follow the files.** Board, Schematic (with its sheets), 3D (the board with its parts), Mech, Files, Diff and Browser, all next to the thread. They draw only finished saves and fade in only what changed. Click a pad, track, symbol or pin to see its net, reference, value and footprint, and mention it in chat.

![The power sheet of the schematic beside the thread](docs/media/web-schematic.png)

**Mechanical parts.** Agents model enclosures and brackets in FreeCAD, headless. The Mech tab turns any STEP in 3D, with the project's other parts beside it, and draws standard views on request.

![The case, exploded, on the Mech tab](docs/media/web-mech.png)

**Design history.** Backplane snapshots the KiCad files after every tool call. Step through what the agent did, play it back, jump to the tool call behind a step, or compare any two versions (steps, turns, commits, branches): removed, changed and added items are coloured and the rest dims.

![Compare: the tracks the agent widened](docs/media/web-compare.png)

**Threads per project.** Each thread is an agent session with its own model and provider. Tool calls fold into one line, todo lists and tables render as they should, and threads settle on their own when you stop touching them. Fork a thread, rename it, pin it, or hand it to another.

| The board | Datasheets and files |
|---|---|
| ![](docs/media/web-board.png) | ![](docs/media/web-files.png) |

**A native window.** The desktop app is the same client drawn by Bend itself, with its own board and 3D renderer.

![The native window](docs/media/window-3d.png)

**And more.** A Chrome the agents drive while you watch; agents delegating work to other models; API keys the agents can use without ever reading them; voice input; a terminal per thread. Bots are persistent agents with a face, memory, routines and webhooks, which talk in rooms, across your machines and other people's.

<img src="docs/media/cats.png" width="420" alt="Bots and their moods">

## How you use it

1. Add a project: any folder with a KiCad project in it (several, or one below the root, are fine).
2. Start a thread and ask: "the SSD rails look thin, check them and widen what falls short".
3. Watch the board change as the agent works. Scrub the history bar, open Compare, ask for changes.
4. Leave. Answer its questions or start the next thread from your phone.

## Install

```sh
curl -fsSL https://github.com/i2cjak/Backplane/releases/latest/download/install.sh | sh
backplane
```

Linux (x64, arm64) and macOS (Apple silicon). It installs into `~/.local/share/backplane` and keeps itself up to date (`BACKPLANE_NO_UPDATE=1` turns that off). Releases also carry an AppImage, a `.deb`, an AUR `PKGBUILD` and the Android APK. Nix and NixOS installs are in [Nix / NixOS](#nix--nixos). You need at least one agent CLI (`claude`, `codex` or `grok`) and KiCad; FreeCAD for mechanical work. `backplane --headless` runs it without a window. To pair a phone, scan the QR code in Settings (Pairing link, QR code) with the app, or paste the pairing link.

On a Mac there is no native window yet: `backplane` runs the hub and you use it in the browser at http://127.0.0.1:3787 (and from your phone, as anywhere). Add `~/.local/bin` to your `PATH` if the installer says so.

Nightly builds of `main` are prereleases on the [Releases](https://github.com/i2cjak/Backplane/releases) page, each with its own installer: `curl -fsSL https://github.com/i2cjak/Backplane/releases/download/<tag>/install.sh | sh`.

## Build

Needs [Bend](https://bend-lang.com), clang 19+, X11 headers and bun. On macOS, Xcode's clang is enough and there are no X11 headers to find: `scripts/build.sh` builds the hub and web client only.

```sh
scripts/check.sh   # type-check everything, prove every law
scripts/test.sh    # tests
scripts/build.sh   # dist/: the app, the server and the web client
```

Backplane is written in Bend, and the rules that matter are laws proven in [`PROOF.bend`](PROOF.bend). [AGENTS.md](AGENTS.md) describes the layout; [mobile/README.md](mobile/README.md) the phone apps.

## Nix / NixOS

The flake packages the official Linux release binaries (`x86_64-linux` and `aarch64-linux`) from [i2cjak/Backplane](https://github.com/i2cjak/Backplane). It does not compile Backplane. nixpkgs is pinned to `nixos-26.05`. `packages.default` is `backplane`; `overlays.default` adds that package; `apps.default` runs it; `nix fmt` is alejandra.

```sh
nix run .          # the window binary; a hub starts with it
nix build
nix flake check
```

There is no `--version`. An unknown flag is ignored, and a hub would start on the default home. The version is the `backplane` field of `GET /hello`, which is CBOR, not a text banner. The flake's `version` check starts the packaged binary and reads that.

A NixOS configuration:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.backplane.url = "github:Riceman2000/Backplane";

  outputs = { nixpkgs, backplane, ... }: {
    nixosConfigurations.box = nixpkgs.lib.nixosSystem {
      modules = [
        backplane.nixosModules.default
        { nixpkgs.overlays = [ backplane.overlays.default ]; }
        ({ pkgs, ... }: {
          services.backplane = {
            enable = true;
            # Loopback unless you mean to publish the hub.
            host = "127.0.0.1";
            port = 3787;
            openFirewall = false;
            tailscale.enable = true;
            extraPackages = [ pkgs.git pkgs.kicad pkgs.freecad ];
            # Strings, not path literals. A path would be copied into the
            # Nix store, and the module rejects store paths.
            environmentFile = "/run/secrets/backplane.env";
            credentials.CLAUDE_CODE_OAUTH_TOKEN = "/run/secrets/claude-token";
            # A tree containing skills/pcb/SKILL.md. Omit it and the hub
            # downloads the pin itself (needs a network).
            # kistack.source = ./kistack;
            # kistack.readOnly = true;
          };
        })
      ];
    };
  };
}
```

The service runs `backplane-serve` (it stays in the foreground; `backplane --headless` without `--foreground` detaches). State is `--home` (`/var/lib/backplane` by default), owned by the `backplane` user. `XDG_CACHE_HOME` is `/var/cache/backplane`. The package and the unit set `BACKPLANE_NO_UPDATE=1`. The account lingers so upstream can put each agent in a `systemd-run --user` scope; without a user manager those agents run unconfined.

`tailscale.enable` puts `tailscale` on `PATH` and orders the service after `tailscaled.service` and `tailscaled-autoconnect.service` with `Wants=`, so a machine without the autoconnect unit still boots. Upstream reads `tailscale ip -4` once at start.

KiStack is hardcoded to `$HOME/.cache/backplane/kistack` (not `XDG_CACHE_HOME`). Upstream writes into that tree and, on a later start, prefers whatever `current` names, which a background refresh sets to GitHub HEAD. There is no upstream switch for a pin or a read-only tree. `kistack.source` is copied into that cache; `kistack.readOnly` (the default) then points `current` at `kistack.revision` and removes write permission. The refresh's failed writes are ignored.

The pairing token is 128 hex characters in `<home>/token` (mode 0600). Upstream prints it on stdout only when the tailnet listener binds (`pairing token <hex>`, and `#token=<hex>` with `--tailscale-https`). The service redacts those before the journal, and a journal pattern drops a raw token line if one is printed anyway. With `--no-tailscale` the token is not printed.

`environmentFile` and `credentials` must be absolute paths outside `/nix/store`. Credential files are loaded with `LoadCredential` and exported under the attribute name. A `PathChanged` path unit (not `PathExists`) restarts the hub when one of those files changes. Agents inherit the hub environment from when they were spawned; upstream does not re-read it.

To bump the pin, from a checkout:

```sh
nix/update.sh            # latest stable GitHub release
nix/update.sh v0.11.1    # one tag
nix fmt
```

`nix/update.sh` rewrites `nix/sources.nix` from that release's `SHA256SUMS` and from the tag's `KiStack.revision()` in `src/server/kicad.bend`. It needs `curl` and `python3`.

## License

MIT. See [LICENSE](LICENSE). `backplane-step2glb` embeds OpenCascade (LGPL-2.1); its notices ship in `licenses/`.
