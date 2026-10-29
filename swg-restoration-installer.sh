#!/usr/bin/env bash
# SWG Restoration Linux Installer - unofficial, community made.
# https://github.com/hsmasteryoda/swg-restoration-linux
#
# A point-and-click installer for Star Wars Galaxies Restoration (swgr.org) on Linux. It automates the
# "Installation using Wine" method from SWGR's wiki (swgr.org/wiki/linux_install) and runs SWGR's own signed
# installer, downloaded from their patch server. No game files are included or redistributed.
#
#   ./swg-restoration-installer.sh                     GUI install (or repair)
#   ./swg-restoration-installer.sh --prefix DIR        install into DIR instead of ~/Games/swg-restoration
#   ./swg-restoration-installer.sh --installer FILE    use an already-downloaded "SWG Restoration Install.exe"
#   ./swg-restoration-installer.sh --resolution WxH[@Hz]   (re)write the game's user.cfg screen mode
#   ./swg-restoration-installer.sh --uninstall         remove everything this installer made
#   ./swg-restoration-installer.sh --no-gui            same steps in the terminal only
#
# Steps: Wine prefix -> winetricks settings (win10, hidewineexports=enable, windowmanagerdecorated=n,
# windowmanagermanaged=y) and components (d3dcompiler_43 d3dx10 d3dx9 d3dx9_39 dxvk xact xact_x64 vcrun2022
# corefonts) -> SWGR installer + launcher (you sign in and patch) -> user.cfg with your screen size (the wiki's
# fix for 1024x768-only on KDE + NVIDIA) -> app-menu entry with the launcher's icon.
set -uo pipefail

VERSION="1.0.0"
APP="SWG Restoration"
TITLE="SWG Restoration Linux Installer"
PREFIX="${HOME}/Games/swg-restoration"
URL="https://patch.swgr.org/patch/launcher/SWG%20Restoration%20Install.exe"
WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
BIN="${HOME}/.local/bin/swg-restoration"
DESKTOP="${HOME}/.local/share/applications/swg-restoration.desktop"
ICON="${HOME}/.local/share/icons/hicolor/256x256/apps/swg-restoration.png"
LOCAL_INSTALLER="" RESOLUTION="" RES_FLAG=0 UNINSTALL=0 GUI=1 PREFIX_SET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX="$(realpath -m "$2")"; PREFIX_SET=1; shift 2 ;;
        --installer) LOCAL_INSTALLER="$(realpath "$2")"; shift 2 ;;
        --resolution) RESOLUTION="$2"; RES_FLAG=1; [ "$RESOLUTION" = auto ] && RESOLUTION=""; shift 2 ;;
        --uninstall) UNINSTALL=1; shift ;;
        --no-gui) GUI=0; shift ;;
        --version) echo "$VERSION"; exit 0 ;;
        -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
        *) echo "unknown option: $1 (try --help)"; exit 2 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }
{ [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && have zenity; } || GUI=0
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/swg-restoration-installer.log"
mkdir -p "$(dirname "$LOG")"
: > "$LOG"

z() { zenity --title="$TITLE" --width=520 "$@" 2>/dev/null; }
say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; printf '==> %s\n' "$*" >> "$LOG"; }
info() { if [ "$GUI" = 1 ]; then z --info --no-wrap --text="$*"; else printf '\n%s\n' "$*"; fi; }
die() {
    printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2
    printf 'ERROR: %s\n' "$*" >> "$LOG"
    [ "$GUI" = 1 ] && z --error --text="$*\n\nDetails: $LOG"
    exit 1
}
ask() {  # ask "question" -> 0 yes / 1 no
    if [ "$GUI" = 1 ]; then z --question --text="$1" --ok-label="${2:-Yes}" --cancel-label="${3:-No}"
    else read -r -p "$1 [y/N] " a; [[ "$a" =~ ^[Yy] ]]; fi
}

# Progress: in GUI mode one zenity progress window lives for the whole run; step "text" moves it.
PROG_FD=""
progress_start() {
    [ "$GUI" = 1 ] || return 0
    exec {PROG_FD}> >(zenity --progress --title="$TITLE" --width=520 --auto-close --no-cancel \
        --text="Starting..." --percentage=0 2>/dev/null)
}
step() {  # step PERCENT "text"
    say "$2"
    [ -n "$PROG_FD" ] && printf '%s\n# %s\n' "$1" "$2" >&"$PROG_FD"
    return 0
}
progress_end() { [ -n "$PROG_FD" ] && { printf '100\n' >&"$PROG_FD"; exec {PROG_FD}>&-; PROG_FD=""; sleep 0.3; }; return 0; }
run() { "$@" >> "$LOG" 2>&1; }  # quiet in GUI mode, everything goes to the log

# ---------------------------------------------------------------- uninstall
if [ "$UNINSTALL" = 1 ]; then
    ask "Remove SWG Restoration?\n\nThis deletes $PREFIX (the game, its Wine setup and launcher settings)\nand the app-menu entry. Your swgr.org account is not affected." "Remove" "Cancel" || exit 0
    WINEPREFIX="$PREFIX" wineserver -k 2>/dev/null
    rm -rf -- "$PREFIX"; rm -f -- "$BIN" "$DESKTOP" "$ICON"
    have update-desktop-database && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null
    info "SWG Restoration was removed."
    exit 0
fi

# ---------------------------------------------------------------- welcome + location
if [ "$GUI" = 1 ] && [ ! -f "$PREFIX/drive_c/SWG Restoration/SWG Restoration.exe" ]; then
    z --question --ok-label="Install" --cancel-label="Cancel" --text="<b>Star Wars Galaxies Restoration for Linux</b>  (unofficial installer v$VERSION)

This sets up Wine the way SWGR's Linux wiki describes, then runs SWGR's
own installer. You need a free account from swgr.org to log in.

  1. Wine setup and components - automatic, about 5-10 minutes
  2. SWGR's installer and launcher - you sign in and let it patch the game
     (about 4 GB) into a new empty folder, then close the launcher
  3. Screen-size fix and an app-menu entry - automatic

Install location: $PREFIX" || exit 0
    if [ "$PREFIX_SET" = 0 ] && ask "Install to the default location?\n\n$PREFIX" "Use default" "Choose folder..."; then :
    elif [ "$PREFIX_SET" = 0 ]; then
        d="$(z --file-selection --directory --filename="$HOME/")" || exit 0
        PREFIX="$d/swg-restoration"
    fi
fi
EXE="$PREFIX/drive_c/SWG Restoration/SWG Restoration.exe"

# ---------------------------------------------------------------- dependencies
missing=()
for c in wine wineserver curl cabextract unzip sha256sum; do have "$c" || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
    cmd=""
    if have pacman; then cmd="pacman -S --needed --noconfirm wine cabextract unzip curl"
    elif have apt-get; then cmd="sh -c 'dpkg --add-architecture i386 && apt-get update && apt-get install -y wine wine64 wine32 cabextract unzip curl'"
    elif have dnf; then cmd="dnf install -y wine cabextract unzip curl"
    elif have zypper; then cmd="zypper --non-interactive install wine cabextract unzip curl"
    fi
    [ -n "$cmd" ] || die "Please install these first: ${missing[*]}"
    if have pkexec && ask "These programs are needed and missing: ${missing[*]}\n\nInstall them now? (asks for your password)\n\n$cmd" "Install" "Cancel"; then
        pkexec sh -c "$cmd" >> "$LOG" 2>&1 || die "Installing ${missing[*]} failed. Run this in a terminal:\nsudo $cmd"
    else
        die "Please install these first: ${missing[*]}\n\nsudo $cmd"
    fi
fi
have vulkaninfo && ! vulkaninfo --summary >/dev/null 2>&1 &&
    info "Warning: Vulkan doesn't seem to work on this PC.\nThe game uses DXVK, which needs a Vulkan graphics driver\n(NVIDIA: also the 32-bit driver package, e.g. lib32-nvidia-utils)."

export WINEPREFIX="$PREFIX" WINEARCH=win64 WINEDEBUG=-all
TOOLS="$PREFIX/.installer"
mkdir -p "$TOOLS" "$(dirname "$BIN")" "$(dirname "$DESKTOP")" "$(dirname "$ICON")" || die "Can't create $PREFIX"
echo "$TITLE $VERSION, $(wine --version), prefix $PREFIX" >> "$LOG"

progress_start
# ---------------------------------------------------------------- 1. prefix
if [ ! -f "$PREFIX/system.reg" ]; then
    step 5 "Creating the Wine setup in $PREFIX..."
    run wineboot -i || die "Wine couldn't create its setup (wineboot failed)"
    run wineserver -w
fi

# ---------------------------------------------------------------- 2. winetricks
WT="$(command -v winetricks || true)"
if [ -z "$WT" ] || [ "$("$WT" --version 2>/dev/null | cut -c1-4)" \< "2024" ]; then
    WT="$TOOLS/winetricks"
    step 10 "Downloading winetricks..."
    run curl -fsSL -o "$WT" "$WINETRICKS_URL" || die "Couldn't download winetricks (internet connection?)"
    chmod +x "$WT"
fi
if [ ! -f "$TOOLS/winetricks.done" ]; then
    step 15 "Wine settings: Windows 10, window manager, hide Wine..."
    run "$WT" -q win10 hidewineexports=enable windowmanagerdecorated=n windowmanagermanaged=y ||
        die "winetricks settings failed"
    i=0; total=9
    for v in d3dcompiler_43 d3dx10 d3dx9 d3dx9_39 dxvk xact xact_x64 vcrun2022 corefonts; do
        i=$((i + 1))
        step $((15 + i * 55 / total)) "Installing $v ($i of $total)...  (Visual C++ may show 'Setup Failed' - that's harmless)"
        run "$WT" -q "$v" || echo "WARNING: winetricks $v reported an error (continuing)" >> "$LOG"
    done
    run wineserver -w
    touch "$TOOLS/winetricks.done"
fi

# ---------------------------------------------------------------- 3. SWGR installer
if [ ! -f "$EXE" ]; then
    step 72 "Downloading SWGR's installer from patch.swgr.org..."
    INST="$PREFIX/drive_c/SWG Restoration Install.exe"
    if ! run curl -fsSL -o "$INST" "$URL"; then
        [ -n "$LOCAL_INSTALLER" ] || die "Couldn't download SWGR's installer from patch.swgr.org"
        cp -f -- "$LOCAL_INSTALLER" "$INST"
    fi
    progress_end
    info "<b>Next: SWGR's own installer</b>

  - Accept their license and keep the default folder (C:\\SWG Restoration).
  - The launcher opens: <b>sign in</b> with your swgr.org account.
  - When it asks where to put the game, choose a <b>NEW EMPTY folder</b>
    (for example C:\\SWGR-Game), press <b>Update</b> and wait for patching.
  - When patching is done, <b>close the launcher</b> - this installer then finishes
    (screen-size fix and app-menu entry). Don't start the game yet."
    say "Running SWGR's installer - this continues when you close the launcher"
    (cd "$PREFIX/drive_c" && wine "C:\\SWG Restoration Install.exe" >> "$LOG" 2>&1)
    wineserver -w
    progress_start
fi
[ -f "$EXE" ] || die "SWGR's launcher wasn't installed (C:\\SWG Restoration\\SWG Restoration.exe is missing).\nWas the installer cancelled? Run this installer again to retry."

# The installer may close (or its launcher may quit) before the game is patched: then open the launcher here and
# wait until it is closed, so the screen-size fix below can find the game's options.cfg.
if [ "$RES_FLAG" = 0 ] && [ -z "$(find "$PREFIX/drive_c" -maxdepth 4 -name SwgClient_r.exe -print -quit 2>/dev/null)" ]; then
    progress_end
    info "<b>The game isn't patched yet.</b>

The SWG Restoration launcher opens next: sign in, choose a NEW EMPTY folder
for the game (e.g. C:\\SWGR-Game), press <b>Update</b>, and close the launcher
when patching is finished. This installer then completes."
    say "Waiting for the SWGR launcher to be closed"
    (cd "$PREFIX/drive_c/SWG Restoration" && wine "SWG Restoration.exe" >> "$LOG" 2>&1)
    wineserver -w
    progress_start
fi

# ---------------------------------------------------------------- 4. screen size (user.cfg)
step 85 "Screen-size fix..."
GAMECFG="$(find "$PREFIX/drive_c" -maxdepth 4 -name options.cfg -printf '%T@ %h\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
if [ -z "$GAMECFG" ]; then  # options.cfg may only appear after the first game start: use the client's folder
    client="$(find "$PREFIX/drive_c" -maxdepth 4 -name SwgClient_r.exe -printf '%h\n' 2>/dev/null | head -1)"
    [ "$(basename "${client:-x}")" = x64 ] && client="$(dirname "$client")"
    GAMECFG="$client"
fi
if [ -z "$RESOLUTION" ] && have xrandr; then  # largest connected output's current mode (XWayland reports it too)
    RESOLUTION="$(xrandr --current 2>/dev/null | awk '/ connected/{c=1;next} /^[^ ]/{c=0} c && /\*/{split($1,r,"x"); for(i=2;i<=NF;i++) if($i ~ /\*/){hz=$i; gsub(/[*+]/,"",hz)} if(r[1]*r[2]>best){best=r[1]*r[2]; m=$1"@"int(hz+0.5)}} END{print m}')"
fi
if [ -n "$GAMECFG" ] && [ -n "$RESOLUTION" ]; then
    w="${RESOLUTION%%x*}"; rest="${RESOLUTION#*x}"; h="${rest%%@*}"; hz=60
    [ "$rest" != "$h" ] && hz="${rest#*@}"
    if [[ "$w$h$hz" =~ ^[0-9]+$ ]]; then
        if [ "$RES_FLAG" = 0 ] && [ -f "$GAMECFG/user.cfg" ] && ! grep -q 'swg-restoration-installer' "$GAMECFG/user.cfg"; then
            echo "keeping the existing $GAMECFG/user.cfg" >> "$LOG"
        else
            printf '# written by swg-restoration-installer (swgr.org wiki fix for 1024x768-only on KDE + NVIDIA)\n[ClientGraphics]\nscreenWidth=%s\nscreenHeight=%s\n\n[Direct3d9]\nFullscreenRefreshRate=%s\n' \
                "$w" "$h" "$hz" > "$GAMECFG/user.cfg"
            echo "user.cfg: ${w}x${h} @ ${hz} Hz in $GAMECFG" >> "$LOG"
        fi
    fi
fi

if [ "$RES_FLAG" = 1 ] && [ -f "$DESKTOP" ]; then  # menu action "Fix screen size": nothing else to do
    progress_end
    info "Screen size set to ${w:-?}x${h:-?} @ ${hz:-?} Hz\n($GAMECFG/user.cfg)"
    exit 0
fi

# ---------------------------------------------------------------- 5. menu entry
step 92 "Adding SWG Restoration to your app menu..."
SELF="$TOOLS/swg-restoration-installer.sh"   # kept inside the install so the menu actions survive deleting the download
[ "$(realpath "$0")" = "$SELF" ] || cp -f -- "$0" "$SELF"
chmod +x "$SELF"
cat > "$BIN" <<EOF
#!/usr/bin/env bash
# Starts the SWG Restoration launcher in its Wine setup (made by swg-restoration-installer).
export WINEPREFIX="$PREFIX" WINEDEBUG=-all DXVK_LOG_LEVEL=none
cd "$PREFIX/drive_c/SWG Restoration" || exit 1
exec wine "SWG Restoration.exe" "\$@"
EOF
chmod +x "$BIN"
icodir="$TOOLS/icon"; rm -rf "$icodir"; mkdir -p "$icodir"
if have 7z && 7z x -y -o"$icodir" "$EXE" '.rsrc/ICON/*' '.rsrc/*/ICON/*' >/dev/null 2>&1 && have python3; then
    best="$(find "$icodir" -type f -path '*ICON*' -printf '%s %p\n' | sort -rn | head -1 | cut -d' ' -f2-)"
    [ -n "$best" ] && python3 - "$best" "$ICON" >> "$LOG" 2>&1 <<'PY'
import struct, sys
from PIL import Image
d = open(sys.argv[1], "rb").read()
if d[:4] == b"\x00\x00\x01\x00":            # .ico wrapper from 7z: jump to the first image
    d = d[struct.unpack("<I", d[18:22])[0]:]
if d[:8] == b"\x89PNG\r\n\x1a\n":
    open(sys.argv[2], "wb").write(d); sys.exit()
hs, w, h2, _, bpp = struct.unpack("<IiiHH", d[:16])
if bpp != 32:
    sys.exit("icon is not 32-bit")
h = abs(h2) // 2 if abs(h2) == 2 * w else abs(h2)
im = Image.frombuffer("RGBA", (w, h), d[hs:hs + w * h * 4], "raw", "BGRA", 0, -1)  # bottom-up, no AND mask
im.resize((256, 256), Image.LANCZOS).save(sys.argv[2])
PY
fi
ICONREF="$ICON"; [ -f "$ICON" ] || ICONREF="applications-games"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=SWG Restoration
Comment=Star Wars Galaxies Restoration (unofficial Linux setup, via Wine)
Exec="$BIN"
Icon=$ICONREF
Terminal=false
Categories=Game;
StartupWMClass=swg restoration.exe
Actions=resolution;uninstall;

[Desktop Action resolution]
Name=Fix screen size (rewrite user.cfg)
Exec="$SELF" --prefix "$PREFIX" --resolution auto

[Desktop Action uninstall]
Name=Uninstall SWG Restoration
Exec="$SELF" --prefix "$PREFIX" --uninstall
EOF
have update-desktop-database && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null
progress_end

if [ "$GUI" = 1 ]; then
    z --question --ok-label="Play now" --cancel-label="Close" --text="<b>SWG Restoration is installed.</b>

Start it any time from your app menu (Games > SWG Restoration).

Tips from SWGR's wiki:
  - Graphics glitches: in the launcher's game settings choose \"Shader 2.0\".
  - Wrong screen size: right-click the menu entry > Fix screen size.
  - Install log: $LOG" && { setsid "$BIN" >/dev/null 2>&1 & }
else
    printf '\nDone. Start it from your app menu or run: %s\nLog: %s\n' "$BIN" "$LOG"
fi
