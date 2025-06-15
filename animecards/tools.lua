-- This module was intended to be named 'utils',
-- but 'mp.utils' is already in use. Named 'tools' to avoid confusion.
-- Yeah, this module is stupid...
local opts = require('script_options')

local tools = {}

function tools.dlog(...)
  if opts.DEBUG_MODE == true then
    print(...)
  end
end

function tools.format_time(raw_seconds, are_ms_needed)
  local hours = math.floor(raw_seconds / 3600)
  local minutes = math.floor((raw_seconds % 3600) / 60)
  local seconds = math.floor(raw_seconds % 60)
  local milliseconds = math.floor((raw_seconds * 1000) % 1000)

  -- MM:SS
  local formatted_time = string.format("%02d:%02d", minutes, seconds)

  -- HH:MM:SS
  if hours > 0 then
    formatted_time = string.format("%02d:", hours) .. formatted_time
  end

  -- HH:MM:SS:MSS
  if are_ms_needed == true then
    formatted_time = formatted_time .. string.format(":%03d", milliseconds)
  end

  return formatted_time
end

return tools
