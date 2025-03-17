------------- Instructions -------------
-- -- Video Demonstration: https://www.youtube.com/watch?v=M4t7HYS73ZQ
-- IF USING WEBSOCKET (RECOMMENDED)
-- -- Install the mpv_webscoket extension: https://github.com/kuroahna/mpv_websocket
-- -- Open a LOCAL copy of https://github.com/Renji-XD/texthooker-ui
-- -- Configure the script (if you're not using the Lapis note format)
-- IF USING CLIPBOARD INSERTER (NOT RECOMMENDED)
-- -- Install the clipboard inserter plugin: https://github.com/laplus-sadness/lap-clipboard-inserter
-- -- Open the texthooker UI, enable the plugin and enable clipboard pasting: https://github.com/Renji-XD/texthooker-ui
-- BOTH
-- -- Wait for an unknown word and create the card with Yomichan.
-- -- Select all the subtitle lines you wish to add to the card and copy with Ctrl + c.
-- -- Press Ctrl + v in MPV to add the lines, their Audio and the currently paused image to the back of the card.
---------------------------------------

------------- Credits -------------
-- Credits and copyright go to Anacreon DJT: https://anacreondjt.gitlab.io/
------------------------------------

------------- Original Credits (Outdated) -------------
-- This script was made by users of 4chan's Daily Japanese Thread (DJT) on /jp/
-- More information can be found here http://animecards.site/
-- Message @Anacreon with bug reports and feature requests on Discord (https://animecards.site/discord/) or 4chan (https://boards.4channel.org/jp/#s=djt)
--
-- If you like this work please consider subscribing on Patreon!
-- https://www.patreon.com/Quizmaster
------------------------------------

local utils = require 'mp.utils'
local msg = require 'mp.msg'

------------- User Config -------------
-- Set these to match your field names in Anki
local FRONT_FIELD = "Expression"
local SENTENCE_AUDIO_FIELD = "SentenceAudio"
local SENTENCE_FIELD = "SentenceFurigana"
local IMAGE_FIELD = "Picture"
-- Optional padding and fade settings in seconds.
-- Padding grabs extra audio around your selected subs.
-- Fade does a volume fade effect at the beginning and end of the resulting audio.
local AUDIO_CLIP_FADE = 0.2
local AUDIO_CLIP_PADDING = 0.75
-- Optional play sentence audio automatically after card update
local AUTOPLAY_AUDIO = false
-- Optional screenshot image format. Valid options: "webp" or "png"
-- Change to "png" if you plan to view cards on iOS or Mac.
local IMAGE_FORMAT = "png"
-- Optional set to true if you want your volume in mpv to affect Anki card volume.
local USE_MPV_VOLUME = false
---------------------------------------

local subs = {}
local enable_subs_to_clip = false
local debug_mode = true
local use_powershell_clipboard = nil

if unpack ~= nil then table.unpack = unpack end

local o = {}
local platform = mp.get_property_native("platform")
if platform == "darwin" then
  platform = "macos"

local display_server
if os.getenv("WAYLAND_DISPLAY") ~= "" then
	display_server = 'wayland'
elseif platform == 'linux' then
	display_server = 'xorg'
else
	display_server = ""
end

local function dlog(...)
  if debug_mode then
    print(...)
  end
end

local function anki_connect(action, params)
  local request
  request = utils.format_json({action=action, params=params, version=6})
  local args = {'curl', '-s', 'localhost:8765', '-X', 'POST', '-d', request}
  
  dlog("AnkiConnect request: " .. request)
  
  local result = utils.subprocess({ args = args, cancellable = false, capture_stderr = true })
  
  if result.status ~= 0 then
    msg.error("Curl command failed with status: " .. tostring(result.status))
    msg.error("Stderr: " .. (result.stderr or "none"))
    return nil
  end
  
  if not result.stdout or result.stdout == "" then
    msg.error("Empty response from AnkiConnect")
    return nil
  end
  
  dlog("AnkiConnect response: " .. result.stdout)
  
  local success, parsed_result = pcall(function() return utils.parse_json(result.stdout) end)
  if not success or not parsed_result then
    msg.error("Failed to parse JSON response: " .. (result.stdout or "empty"))
    return nil
  end
  
  return parsed_result
end

-- Get media directory path from AnkiConnect
local prefix = ""
local media_dir_response = anki_connect('getMediaDirPath')

if not media_dir_response then
  msg.error("AnkiConnect call failed completely")
  mp.osd_message("Error: Failed to communicate with AnkiConnect", 5)
  return
elseif media_dir_response["error"] then
  msg.error("AnkiConnect error: " .. tostring(media_dir_response["error"]))
  mp.osd_message("AnkiConnect error: " .. tostring(media_dir_response["error"]), 5)
  return
elseif media_dir_response["result"] then
  prefix = media_dir_response["result"]
  dlog("Got media directory path from AnkiConnect: " .. prefix)
else
  msg.error("Unexpected response format from AnkiConnect")
  mp.osd_message("Error: Unexpected response from AnkiConnect", 5)
  return
end

local function clean(s)
  for _, ws in ipairs({'%s', ' ', '᠎', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '​', ' ', ' ', '　', '﻿', '‪'}) do
    s = s:gsub(ws..'+', "")
  end
  return s
end

local function get_name(s, e)
  return mp.get_property("filename"):gsub('%W','').. tostring(s) .. tostring(e)
end

local function get_clipboard()
  local res
  if platform == 'windows' then
    res = utils.subprocess({ args = {
      'powershell', '-NoProfile', '-Command', [[& {
        Trap {
          Write-Error -ErrorRecord $_
          Exit 1
        }
        $clip = ""
        if (Get-Command "Get-Clipboard" -errorAction SilentlyContinue) {
          $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
        } else {
          Add-Type -AssemblyName PresentationCore
          $clip = [Windows.Clipboard]::GetText()
        }
        $clip = $clip -Replace "`r",""
        $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
        [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
      }]]
    } })
  elseif platform == 'macos' then
    return io.popen('LANG=en_US.UTF-8 pbpaste'):read("*a")
  else -- platform == 'linux'
    if display_server == 'wayland' then
      res = utils.subprocess({ args = {
        'wl-paste'
      } })
    else -- display_server == 'xorg'
      res = utils.subprocess({ args = {
        'xclip', '-selection', 'clipboard', '-out'
      } })
    end
  end
  if not res.error then
    return res.stdout
  end
end

local function powershell_set_clipboard(text)
  utils.subprocess({ args = {
    'powershell', '-NoProfile', '-Command', [[Set-Clipboard -Value @"]] .. "\n" .. text .. "\n" .. [["@]]
  }})
end

local function cmd_set_clipboard(text)
  local cmd = 'echo ' .. text .. ' | clip';
  mp.command("run cmd /D /C " .. cmd);
end

local function determine_clip_type()
  powershell_set_clipboard([[Anacreon様]])
  use_powershell_clipboard = get_clipboard() == [[Anacreon様]]
end

local function linux_set_clipboard(text)
  if display_server == 'wayland' then
    os.execute('wl-copy <<EOF\n' .. text .. '\nEOF\n')
  else -- display_server == 'xorg'
    os.execute('xclip -selection clipboard <<EOF\n' .. text .. '\nEOF\n')
  end
end

local function macos_set_clipboard(text)
  os.execute('export LANG=en_US.UTF-8; cat <<EOF | pbcopy\n' .. text .. '\nEOF\n')
end

local function record_sub(_, text)
  if text and mp.get_property_number('sub-start') and mp.get_property_number('sub-end') then
    local sub_delay = mp.get_property_native("sub-delay")
    local audio_delay = mp.get_property_native("audio-delay")
    local newtext = clean(text)
    if newtext == '' then
      return
    end

    subs[newtext] = { mp.get_property_number('sub-start') + sub_delay - audio_delay, mp.get_property_number('sub-end') + sub_delay - audio_delay }
    dlog(string.format("%s -> %s : %s", subs[newtext][1], subs[newtext][2], newtext))
    if enable_subs_to_clip then
      -- Remove newlines from text before sending it to clipboard.
      -- This way pressing control+v without copying from texthooker page
      -- will always give last line.
      text = string.gsub(text, "[\n\r]+", " ")
      if platform == 'windows' then
        if use_powershell_clipboard == nil then
          determine_clip_type()
        end
        if use_powershell_clipboard then
          powershell_set_clipboard(text)
        else
          cmd_set_clipboard(text)
        end
      elseif platform == 'macos' then
        macos_set_clipboard(text)
      else
        linux_set_clipboard(text)
      end
    end
  end
end

local function create_audio(s, e)

  if s == nil or e == nil then
    return
  end

  local name = get_name(s, e)
  local destination = utils.join_path(prefix, name .. '.mp3')
  s = s - AUDIO_CLIP_PADDING
  local t = e - s + AUDIO_CLIP_PADDING
  local source = mp.get_property("path")
  local aid = mp.get_property("aid")

  local tracks_count = mp.get_property_number("track-list/count")
  for i = 1, tracks_count do
    local track_type = mp.get_property(string.format("track-list/%d/type", i))
    local track_selected = mp.get_property(string.format("track-list/%d/selected", i))
    if track_type == "audio" and track_selected == "yes" then
      if mp.get_property(string.format("track-list/%d/external-filename", i), o) ~= o then
        source = mp.get_property(string.format("track-list/%d/external-filename", i))
        aid = 'auto'
      end
      break
    end
  end


  local cmd = {
    'run',
    'mpv',
    source,
    '--loop-file=no',
    '--video=no',
    '--no-ocopy-metadata',
    '--no-sub',
    '--audio-channels=1',
    string.format('--start=%.3f', s),
    string.format('--length=%.3f', t),
    string.format('--aid=%s', aid),
    string.format('--volume=%s', USE_MPV_VOLUME and mp.get_property('volume') or '100'),
    string.format("--af-append=afade=t=in:curve=ipar:st=%.3f:d=%.3f", s, AUDIO_CLIP_FADE),
    string.format("--af-append=afade=t=out:curve=ipar:st=%.3f:d=%.3f", s + t - AUDIO_CLIP_FADE, AUDIO_CLIP_FADE),
    string.format('-o=%s', destination)
  }
  mp.commandv(table.unpack(cmd))
  dlog(utils.to_string(cmd))
end

local function create_screenshot(s, e)
  local source = mp.get_property("path")
  local img = utils.join_path(prefix, get_name(s,e) .. '.' .. IMAGE_FORMAT)

  local cmd = {
    'run',
    'mpv',
    source,
    '--loop-file=no',
    '--audio=no',
    '--no-ocopy-metadata',
    '--no-sub',
    '--frames=1',
  }
  if IMAGE_FORMAT == 'webp' then
    table.insert(cmd, '--ovc=libwebp')
    table.insert(cmd, '--ovcopts-add=lossless=0')
    table.insert(cmd, '--ovcopts-add=compression_level=6')
    table.insert(cmd, '--ovcopts-add=preset=drawing')
  elseif IMAGE_FORMAT == 'png' then
    table.insert(cmd, '--vf-add=format=rgb24')
  end
  table.insert(cmd, '--vf-add=scale=480*iw*sar/ih:480')
  table.insert(cmd, string.format('--start=%.3f', mp.get_property_number("time-pos")))
  table.insert(cmd, string.format('-o=%s', img))
  mp.commandv(table.unpack(cmd))
  dlog(utils.to_string(cmd))
end



local function add_to_last_added(ifield, afield, tfield)
  local added_notes = anki_connect('findNotes', {query='added:1'})["result"]
  table.sort(added_notes)
  local noteid = added_notes[#added_notes]
  local note = anki_connect('notesInfo', {notes={noteid}})

  if note ~= nil then
    local word = note["result"][1]["fields"][FRONT_FIELD]["value"]
    local new_fields = {
      [SENTENCE_AUDIO_FIELD]=afield,
      [SENTENCE_FIELD]=tfield,
      [IMAGE_FIELD]=ifield
    }

    anki_connect('updateNoteFields', {
      note={
        id=noteid,
        fields=new_fields
      }
    })

    mp.osd_message("Updated note: " .. word, 3)
    msg.info("Updated note: " .. word)
  end
end

local function get_extract()
  local lines = get_clipboard()
  local e = 0
  local s = 0
  for line in lines:gmatch("[^\r\n]+") do
    line = clean(line)
    dlog(line)
    if subs[line]~= nil then
      if subs[line][1] ~= nil and subs[line][2] ~= nil then
        if s == 0 then
          s = subs[line][1]
        else
          s = math.min(s, subs[line][1])
        end
        e = math.max(e, subs[line][2])
      end
    else
      mp.osd_message("ERR! Line not found: " .. line, 3)
      return
    end
  end
  dlog(string.format('s=%d, e=%d', s, e))
  if e ~= 0 then
    create_screenshot(s, e)
    create_audio(s, e)
    local ifield = '<img src='.. get_name(s,e) ..'.' .. IMAGE_FORMAT .. '>'
    local afield = "[sound:".. get_name(s,e) .. ".mp3]"
    local tfield = string.gsub(string.gsub(lines,"\n+", "<br />"), "\r", "")
    add_to_last_added(ifield, afield, tfield)
    if AUTOPLAY_AUDIO then
      local name = get_name(s, e)
      local audio = utils.join_path(prefix, name .. '.mp3')
      local cmd = {'run', 'mpv', audio, '--loop-file=no', '--load-scripts=no'}
      mp.commandv(table.unpack(cmd))
    end
  end
end

local function ex()
  if debug_mode then
    get_extract()
  else
    pcall(get_extract)
  end
end

local function rec(...)
  if debug_mode then
    record_sub(...)
  else
    pcall(record_sub, ...)
  end
end

local function toggle_sub_to_clipboard()
  enable_subs_to_clip = not enable_subs_to_clip
  mp.osd_message("Clipboard inserter " .. (enable_subs_to_clip and "activated" or "deactived"), 3)
end

local function toggle_debug_mode()
  debug_mode = not debug_mode
  mp.osd_message("Debug mode " .. (debug_mode and "activated" or "deactived"), 3)
end

local function clear_subs(_)
  subs = {}
end

mp.observe_property("sub-text", 'string', rec)
mp.observe_property("filename", "string", clear_subs)

mp.add_key_binding("ctrl+v", "update-anki-card", ex)
mp.add_key_binding("ctrl+t", "toggle-clipboard-insertion", toggle_sub_to_clipboard)
mp.add_key_binding("ctrl+d", "toggle-debug-mode", toggle_debug_mode)
mp.add_key_binding("ctrl+V", ex)
mp.add_key_binding("ctrl+T", toggle_sub_to_clipboard)
mp.add_key_binding("ctrl+D", toggle_debug_mode)
