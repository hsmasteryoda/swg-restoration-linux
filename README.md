# SWG Restoration Linux Installer

A point-and-click installer for **[Star Wars Galaxies Restoration](https://swgr.org)** on Linux.

> **Unofficial.** SWG Restoration supports Windows only and doesn't provide Linux support. This installer
> automates the community-tested *Installation using Wine* method from
> [SWGR's own Linux wiki page](https://swgr.org/wiki/linux_install/) and runs **SWGR's official, signed
> installer**, downloaded from their patch server. No game files are included or redistributed.

## Install

1. Create a free account at [swgr.org](https://swgr.org).
2. Download **`swg-restoration-installer.sh`** from the [latest release](../../releases/latest).
3. Right-click it → **Properties → Permissions → Is executable** (or run `chmod +x swg-restoration-installer.sh`),
   then double-click it (choose **Run** / **Execute**) - or run it from a terminal:

   ```bash
   ./swg-restoration-installer.sh
   ```

4. Follow the windows:
   - Wine is set up automatically (about 5-10 minutes the first time).
   - SWGR's installer opens: accept their license and keep the default folder.
   - The launcher opens: **sign in**, choose a **new empty folder** for the game (e.g. `C:\SWGR-Game`),
     press **Update** and wait for patching (~4 GB).
   - **Close the launcher** when patching finishes - the installer then adds the screen-size fix and an app-menu
     entry, and offers to start the game.

Afterwards start **SWG Restoration** from your app menu (Games). Right-click the entry for
**Fix screen size** or **Uninstall**.

### Requirements

- 64-bit Wine 9.0 or newer, `curl`, `cabextract`, `unzip` - the installer offers to install missing ones
  (pacman, apt, dnf, zypper)
- A working **Vulkan** driver (DXVK). NVIDIA: also the 32-bit driver package (`lib32-nvidia-utils` on Arch/Manjaro)
- `zenity` for the windows (without it, everything runs in the terminal)
- About 6 GB of disk space

## What it does

| Step | Details |
|---|---|
| Wine setup | A separate 64-bit Wine prefix, default `~/Games/swg-restoration` (choose another folder in the first window, or `--prefix DIR`) |
| Settings | `win10`, `hidewineexports=enable`, `windowmanagerdecorated=n`, `windowmanagermanaged=y` (winetricks) |
| Components | `d3dcompiler_43 d3dx10 d3dx9 d3dx9_39 dxvk xact xact_x64 vcrun2022 corefonts` (winetricks; a recent winetricks is downloaded if yours is old or missing). A Visual C++ window may say *Setup Failed* - the wiki says that's harmless |
| SWGR installer | Downloaded from `patch.swgr.org`, copied onto Wine's C: drive (the wiki notes Wine sometimes can't see it otherwise) and started |
| Screen size | Writes `user.cfg` next to the game's `options.cfg` with your monitor's resolution and refresh rate - the wiki's fix for KDE + NVIDIA offering only 1024x768 |
| Shortcuts | A desktop icon and an app-menu entry with the SWGR logo (taken from their launcher), replacing the plain shortcuts Wine creates; `~/.local/bin/swg-restoration` for terminals |

Log: `~/.cache/swg-restoration-installer.log`

## Options

```
./swg-restoration-installer.sh --prefix DIR              install somewhere else
./swg-restoration-installer.sh --installer FILE          use your downloaded "SWG Restoration Install.exe" if the download fails
./swg-restoration-installer.sh --resolution 2560x1440@144   set the game's screen mode (user.cfg)
./swg-restoration-installer.sh --uninstall               remove everything it installed
./swg-restoration-installer.sh --no-gui                  terminal only
```

Running it again repairs an install (finished steps are skipped).

## Lutris

[`lutris/swg-restoration.yml`](lutris/swg-restoration.yml) is the same setup as a Lutris installer
(Lutris enables DXVK through its own Wine runner). Install it with:

```bash
lutris -i lutris/swg-restoration.yml
```

It has also been submitted to lutris.net as **"SWG Restoration (Wine)"** on the
[Star Wars Galaxies page](https://lutris.net/games/star-wars-galaxies-an-empire-divided/). It appears there
once the Lutris moderators approve it.

## Troubleshooting

- **Graphics glitches:** in the launcher's game settings choose **Shader 2.0** (SWGR wiki).
- **Only 1024x768 offered / wrong size:** right-click the menu entry → *Fix screen size*, or use `--resolution`.
- **Launcher or game won't start with your distro's Wine:** SWGR's wiki also documents a Steam method: add
  `~/Games/swg-restoration/drive_c/SWG Restoration/SWG Restoration.exe` as a non-Steam game and set
  Compatibility to **Proton Hotfix**.
- Ask in SWGR's Discord `#technical-help` (mention you're on Linux), or open an issue here for installer problems.

## Credits

- Setup steps: the SWG Restoration wiki's Linux page (TheBlurryOne and contributors)
- [Winetricks](https://github.com/Winetricks/winetricks), [DXVK](https://github.com/doitsujin/dxvk), [Wine](https://www.winehq.org)

SWG Restoration is a fan-made, non-profit project, not affiliated with or endorsed by Daybreak Games, Lucasfilm,
Electronic Arts or Disney. Star Wars™ & © Lucasfilm Ltd. This installer is not affiliated with SWG Restoration.

## License

MIT - see [LICENSE](LICENSE).
