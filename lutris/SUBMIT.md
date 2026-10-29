# Submitting the Lutris installer

Logged in on lutris.net, open the game page
<https://lutris.net/games/star-wars-galaxies-an-empire-divided/> and choose **Add installer** / submit a new
installer. Fill in:

| Field | Value |
|---|---|
| Version | `SWG Restoration (Wine, wiki method 2026)` |
| Runner | `wine` |
| Description | Installs the SWG Restoration (swgr.org) launcher with the setup from SWGR's Linux wiki: Windows 10, hidden Wine exports, window-manager managed windows, and the d3dx/xact/vcrun2022 components. After the installer finishes, sign in to the launcher with your swgr.org account, pick a NEW EMPTY folder for the game files (e.g. C:\SWGR-Game), press Update and wait for patching (~4 GB). If the game offers only 1024x768, create user.cfg next to options.cfg in the game folder with [ClientGraphics] screenWidth=/screenHeight= set to your screen. |
| Notes | Unofficial community installer (github.com/hsmasteryoda/swg-restoration-linux). SWG Restoration supports Windows only and does not provide support for Linux. A Visual C++ 2022 setup window may report "Setup Failed" - that is harmless. Graphics glitches: choose "Shader 2.0" in the launcher's game settings. |
| Credits | Steps from the SWG Restoration wiki Linux page (TheBlurryOne and contributors) |
| Script | the whole content of [`script-for-lutris-form.yml`](script-for-lutris-form.yml) |

Lutris moderators review new installers before they're published.
