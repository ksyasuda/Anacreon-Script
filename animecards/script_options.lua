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
opts.OVERWRITE_LIMIT = 8 -- negative 1 turns off the Limit
opts.HIGHLIGHT_WORD = false
opts.USE_MPV_CLIPBOARD_API = false

-- Audio settings
opts.AUDIO_CLIP_FADE = 0.2     -- seconds
opts.AUDIO_CLIP_PADDING = 0.75 -- seconds
opts.AUDIO_MONO = true
opts.USE_MPV_VOLUME = false
opts.AUTOPLAY_AUDIO = false

-- Image settings (static)
opts.IMAGE_FORMAT = "jpg" -- png | jpg | webp
opts.IMAGE_HEIGHT = 480   -- if 0 then don't scale
opts.JPG_QUALITY = 80     -- 0-100

-- Animated image settings
opts.ANIMATED_IMAGE_ENABLED = false
opts.ANIMATED_IMAGE_FORMAT = "webp" -- webp | avif
opts.ANIMATED_IMAGE_HEIGHT = 480     -- if 0 then don't scale
opts.ANIMATED_IMAGE_FPS = 10         -- 1-30
opts.ANIMATED_IMAGE_QUALITY = 80     -- 0-100 (mapped to CRF for avif)

-- Misc info settings
opts.WRITE_MISCINFO = false
opts.MISCINFO_FIELD = "MiscInfo"
opts.MISCINFO_PATTERN = "[Anacreon Script] %f (%t)" -- %f %F %t %T

function opts.toggle_sub_to_clipboard()
  opts.ENABLE_SUBS_TO_CLIP = not opts.ENABLE_SUBS_TO_CLIP
  mp.osd_message("Clipboard inserter " .. (opts.ENABLE_SUBS_TO_CLIP and "activated" or "deactived"), 3)
end

function opts.toggle_animated_image()
  opts.ANIMATED_IMAGE_ENABLED = not opts.ANIMATED_IMAGE_ENABLED
  mp.osd_message("Animated image " .. (opts.ANIMATED_IMAGE_ENABLED and "enabled" or "disabled"), 2)
end

return opts
