-- Volume, brightness, keyboard backlight, and touchpad controls.
o.bind("XF86AudioRaiseVolume", "Volume up", "blob-audio-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "blob-audio-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "blob-audio-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "blob-audio-input-mute", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "blob-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "blob-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "blob-brightness-display 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "blob-brightness-display 1%", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", "blob-brightness-keyboard up", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", "blob-brightness-keyboard down", { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "blob-brightness-keyboard cycle", { locked = true })
o.bind_toggle("XF86TouchpadToggle", "Toggle touchpad", "touchpad", { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", "blob-toggle-touchpad on", { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", "blob-toggle-touchpad off", { locked = true })

-- Precise volume and brightness controls.
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "blob-audio-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "blob-audio-volume -1", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "blob-brightness-display +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "blob-brightness-display 1%-", { locked = true, repeating = true })

-- Media controls.
o.bind("XF86AudioNext", "Next track", "blob-shell media next", { locked = true })
o.bind("ALT + XF86AudioPlay", "Next track", "blob-shell media next", { locked = true })
o.bind("XF86AudioPause", "Pause", "blob-shell media playPause", { locked = true })
o.bind("XF86AudioPlay", "Play", "blob-shell media playPause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "blob-shell media previous", { locked = true })
o.bind("ALT + SHIFT + XF86AudioPlay", "Previous track", "blob-shell media previous", { locked = true })
o.bind("XF86Eject", "Eject media", "eject", { locked = true })

o.bind("SHIFT + XF86AudioMute", "Switch audio output", "blob-audio-sink-switch", { locked = true })
o.bind("SHIFT + XF86AudioPause", "Switch media source", "blob-audio-source-switch", { locked = true })
o.bind("SHIFT + XF86AudioPlay", "Switch media source", "blob-audio-source-switch", { locked = true })
