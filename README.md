# Anacreon MPV script

Detailed usage guide here: <https://animecards.site/minefromanime/>. Additional instructions in the script itself.

___

This script was created by anacreon from the DJT thread. Find his website here: https://anacreondjt.gitlab.io/

Sadly he seems to have disappeared and no longer provide support or updates to the script. In this repository we organize an effort to maintain and improve the script. 

## Installation Instructions

To install the script, place the 'animecards' folder into your mpv scripts folder and the settings into your mpv script-opts folder.

**Windows:**
```
C:/Users/<YourUsername>/AppData/Roaming/mpv/scripts/animecards
C:/Users/<YourUsername>/AppData/Roaming/mpv/script-opts/animecards.conf
```

**Linux (usually):**
```
~/.config/mpv/scripts/animecards
~/.config/mpv/script-opts/animecards.conf
```

**MacOS:**
```
Depends on your mpv installation.
```

### Final Folder Structure
Your directory structure should look like this:
```
mpv/scripts/animecards
├── main.lua
└── card_builder.lua

mpv/script-opts/animecards.conf
```