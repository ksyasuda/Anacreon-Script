local opts = {}

-- Debug mode
opts.DEBUG_MODE = true

-- Anki field names
opts.FRONT_FIELD = "Expression"
opts.SENTENCE_AUDIO_FIELD = "SentenceAudio"
opts.SENTENCE_FIELD = "SentenceFurigana"
opts.IMAGE_FIELD = "Picture"

-- Behavior settings
opts.ENABLE_SUBS_TO_CLIP = false
opts.ASK_TO_OVERWRITE = true
opts.OVERWRITE_LIMIT = 8 -- -1 turns off the Limit
opts.HIGHLIGHT_WORD = false

-- Audio settings
opts.AUDIO_CLIP_FADE = 0.2     -- seconds
opts.AUDIO_CLIP_PADDING = 0.75 -- seconds
opts.AUTOPLAY_AUDIO = false
opts.USE_MPV_VOLUME = false

-- Image settings
opts.IMAGE_FORMAT = "png" -- png | webp

-- Misc info settings
opts.WRITE_MISCINFO = false
opts.MISCINFO_FIELD = "MiscInfo"
opts.MISCINFO_PATTERN = "[Anacreon Script] %f (%t)" -- %f %F %t %T

function opts.toggle_sub_to_clipboard()
  opts.ENABLE_SUBS_TO_CLIP = not opts.ENABLE_SUBS_TO_CLIP
  mp.osd_message("Clipboard inserter " .. (opts.ENABLE_SUBS_TO_CLIP and "activated" or "deactived"), 3)
end

return opts
