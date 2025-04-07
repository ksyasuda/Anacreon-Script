# Anacreon MPV script

Usage guide here: <https://animecards.site/minefromanime/>

___

This script was created by anacreon from the DJT thread. Find his website here: https://anacreondjt.gitlab.io/

Sadly he seems to have disappeared and no longer provide support or updates to the script and as there is no organized effort to provide LTS for it, I hope we can organize something here. @anacreon if you have a problem with this, please let me know and I will remove this repository.

Usage instructions can be found in the script. 

Notable changes so far:
- Use curl for AnkiConnect requests on all platforms. It seems modern Windows versions also ship with curl now.
- Automatically determine the media directory using AnkiConnect instead of making the user manually input a path. 
- Remove all Forvo related functionality, as that is honestly out of scope. Use this instead: https://github.com/yomidevs/local-audio-yomichan
- Disable subtitle writing to clipboard by default. Use this instead: https://github.com/kuroahna/mpv_websocket .
    - **Subtitle functionality is still used to determine what subtitle lines to use in the Anki card. It may make sense to replace clipboard functionality with a small platform independent subtitle selection menu.**
- The default card fields conform with the Lapis note type by default. If you use [Lapis](https://github.com/donkuri/lapis) or [my fork](https://github.com/friedrich-de/lapis-modified) **(RECOMMENDED)** of it, this script should require zero configuration.
- Added support for Wayland clipboard; Thanks to @kayprish
- Added functionality to open the card browser after adding media and fixed the bug where notes would fail to update when selected in the card browser; Thanks to @adxria


I'm not proficient in Lua. It would be great if someone took over or helped with this project providing LTS.