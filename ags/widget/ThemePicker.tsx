import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { sh, shell } from "../lib/utils"

export const THEMEPICKER_WINDOW = "theme-picker"

const COLUMNS = 3

type Theme = { slug: string; name: string; swatches: string[] }

const swatchProgram =
  "{ key=$1; value=$2; gsub(/[ \\t]/, \"\", key); " +
  "if (match(value, /\"[^\"]*\"/)) value = substr(value, RSTART + 1, RLENGTH - 2); " +
  "else { sub(/#.*$/, \"\", value); gsub(/[ \\t]/, \"\", value) } " +
  "if (value ~ /^#[0-9A-Fa-f]+$/) palette[key] = value } " +
  "END { split(\"color1 color2 color3 color4 color5 color6\", legacy, \" \"); " +
  "split(\"red green yellow blue magenta cyan\", named, \" \"); " +
  "for (i = 1; i <= 6; i++) { " +
  "value = (legacy[i] in palette) ? palette[legacy[i]] : ((named[i] in palette) ? palette[named[i]] : \"\"); " +
  "if (value != \"\") out = (out == \"\" ? value : out \",\" value) } print out }"

const listCommand =
  "{ find \"$HOME/.config/omarchy/themes\" -mindepth 1 -maxdepth 1 -type d 2>/dev/null; " +
  "find \"$OMARCHY_PATH/themes\" -mindepth 1 -maxdepth 1 -type d 2>/dev/null; } | " +
  "while read -r d; do " +
  "[ -f \"$d/colors.toml\" ] || continue; " +
  "n=$(basename \"$d\"); " +
  "[ \"$n\" = blob-dynamic ] && continue; " +
  "c=$(awk -F'=' '" + swatchProgram + "' \"$d/colors.toml\"); " +
  "p=$(echo \"$n\" | sed -E 's/(^|-)([a-z])/\\1\\u\\2/g; s/-/ /g'); " +
  "echo \"$n|$p|$c\"; " +
  "done | awk -F'|' '!seen[$1]++' | sort -t'|' -k2,2"

const themes = createPoll<Theme[]>(
  [],
  5000,
  shell(listCommand),
  (stdout) =>
    stdout
      .split("\n")
      .filter((line) => line.length > 0)
      .map((line) => {
        const [slug, name, swatchStr] = line.split("|")
        const swatches = (swatchStr ?? "")
          .split(",")
          .filter((color) => /^#[0-9A-Fa-f]{3,8}$/.test(color))
        return { slug, name: name ?? slug, swatches }
      }),
)

const currentThemeName = createPoll(
  "",
  2000,
  shell("cat \"$HOME/.local/state/omarchy/current/theme.name\" 2>/dev/null"),
  (stdout) => stdout.trim(),
)

const isDynamic = currentThemeName.as((name) => name === "blob-dynamic")

const rows = themes.as((list) => {
  const chunks: Theme[][] = []
  for (let index = 0; index < list.length; index += COLUMNS) {
    chunks.push(list.slice(index, index + COLUMNS))
  }
  return chunks
})

const applyTheme = (slug: string) => {
  app.toggle_window(THEMEPICKER_WINDOW)
  sh(`"$HOME/scripts/blob_theme.sh" "${slug}"`)
}

const applyDynamic = () => {
  app.toggle_window(THEMEPICKER_WINDOW)
  sh(`"$HOME/scripts/blob_theme.sh" --dynamic`)
}

function Swatches({ colors }: { colors: string[] }) {
  return (
    <box class="theme-swatches" spacing={0}>
      {colors.map((color) => (
        <box class="theme-swatch" css={`background-color: ${color};`} hexpand />
      ))}
    </box>
  )
}

function ThemeChip({ theme }: { theme: Theme }) {
  const active = currentThemeName.as((name) => name === theme.slug)
  return (
    <button
      class={active.as((on: boolean) => (on ? "theme-chip active" : "theme-chip"))}
      onClicked={() => applyTheme(theme.slug)}
      tooltipText={theme.name}
    >
      <box vertical spacing={6}>
        <Swatches colors={theme.swatches} />
        <label class="theme-chip-label" label={theme.name} maxWidthChars={16} />
      </box>
    </button>
  )
}

function DynamicChip() {
  return (
    <button
      class={isDynamic.as((on: boolean) =>
        on ? "theme-chip theme-chip-dynamic active" : "theme-chip theme-chip-dynamic",
      )}
      onClicked={applyDynamic}
      tooltipText="Recolor from the current wallpaper, without changing it"
    >
      <box spacing={8} halign={Gtk.Align.CENTER}>
        <label class="theme-chip-icon" label={""} />
        <label class="theme-chip-label" label="Dynamic (from wallpaper)" />
      </box>
    </button>
  )
}

export default function ThemePicker() {
  const hasThemes = themes.as((list) => list.length > 0)
  const isEmpty = themes.as((list) => list.length === 0)

  return (
    <window
      name={THEMEPICKER_WINDOW}
      namespace={THEMEPICKER_WINDOW}
      class="ThemePicker"
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      exclusivity={Astal.Exclusivity.NORMAL}
      visible={false}
      application={app}
    >
      <box class="panel theme-picker" vertical spacing={12}>
        <box class="panel-header" spacing={8}>
          <label class="panel-title" label="Themes" xalign={0} hexpand halign={Gtk.Align.START} />
          <button
            class="panel-icon-btn"
            tooltipText="Close"
            onClicked={() => app.toggle_window(THEMEPICKER_WINDOW)}
          >
            <label label={""} />
          </button>
        </box>

        <DynamicChip />

        <scrollable
          class="theme-scroll"
          visible={hasThemes}
          hscroll={Gtk.PolicyType.NEVER}
          vscroll={Gtk.PolicyType.AUTOMATIC}
        >
          <box vertical spacing={8}>
            <For each={rows} id={(row: Theme[]) => row.map((t) => t.slug).join("|")}>
              {(row: Theme[]) => (
                <box spacing={8} halign={Gtk.Align.CENTER}>
                  {row.map((theme) => (
                    <ThemeChip theme={theme} />
                  ))}
                </box>
              )}
            </For>
          </box>
        </scrollable>

        <box class="wall-empty" visible={isEmpty} vertical valign={Gtk.Align.CENTER}>
          <label class="wall-empty-icon" label={""} halign={Gtk.Align.CENTER} />
          <label class="wall-empty-text" label="No local themes found" halign={Gtk.Align.CENTER} />
        </box>
      </box>
    </window>
  )
}
