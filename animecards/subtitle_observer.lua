local msg = require 'mp.msg'

local clip = require 'clipboard'
local opts = require 'script_options'
local tools = require 'tools'

local subtitle_observer = {}
local subs = {}

-- Removes various whitespace and invisible characters from a string
local function clean(str)
  for _, ws in ipairs({ '%s', ' ', '᠎', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '​', ' ', ' ', '　', '﻿', '‪' }) do
    str = str:gsub(ws .. '+', "")
  end

  return str
end

function subtitle_observer.record(_, text)
  local sub_start = mp.get_property_number('sub-start')
  local sub_end = mp.get_property_number('sub-end')

  if not text or text == ""
      or not sub_start or not sub_end then
    return
  end

  local sub_delay = mp.get_property_native("sub-delay") or 0
  local newtext = clean(text)

  if newtext == '' then
    return
  end

  local video_start = sub_start + sub_delay
  local video_end = sub_end + sub_delay

  subs[newtext] = { video_start, video_end }

  tools.dlog(string.format("%.3f -> %.3f : %s", video_start, video_end, newtext))

  if opts.ENABLE_SUBS_TO_CLIP == true then
    clip.set(text)
  end
end

function subtitle_observer.clear()
  subs = {}
end

-- Given multiple lines (from clipboard), calculates the
-- combined time range that includes matched subtitles.
function subtitle_observer.specify_range(lines)
  local range_start = 0
  local range_end = 0

  for line in lines:gmatch("[^\r\n]+") do
    line = clean(line)
    tools.dlog("Processing line: " .. line)

    if not subs[line] then
      mp.osd_message("ERR! Line not found: " ..
        line .. "\nIf you're using Renji's texthooker disable the option 'Preserve Whitespace'." ..
        "\nThis is an issue with multi line subs that will be addressed in the future.", 8)
      msg.error("Line not found: " .. line)
      return
    end

    local sub_start = subs[line][1]
    local sub_end = subs[line][2]

    if sub_start and sub_end then
      range_start = (range_start == 0) and sub_start or math.min(range_start, sub_start)
      range_end = math.max(range_end, sub_end)
    end
  end

  tools.dlog(string.format('Lines range: %.3f -> %.3f', range_start, range_end))

  if range_end == 0 then
    mp.osd_message("ERR! No valid subtitles found.", 3)
    msg.error("No valid subtitles found.")
    return
  end

  return range_start, range_end
end

return subtitle_observer
