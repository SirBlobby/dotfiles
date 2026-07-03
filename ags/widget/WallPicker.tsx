import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { sh, shell } from "../lib/utils"

export const WALLPICKER_WINDOW = "wall-picker"

const COLUMNS = 3

type Wallpaper = { name: string; path: string }

const findCommand =
  "find -L \"$HOME/wallpapers\" -maxdepth 1 -type f " +
  "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) " +
  "2>/dev/null | sort"

const wallpapers = createPoll<Wallpaper[]>(
  [],
  5000,
  shell(findCommand),
  (stdout) =>
    stdout
      .split("\n")
      .filter((line) => line.length > 0)
      .map((path) => ({ path, name: path.split("/").pop() ?? path })),
)

const rows = wallpapers.as((list) => {
  const chunks: Wallpaper[][] = []
  for (let index = 0; index < list.length; index += COLUMNS) {
    chunks.push(list.slice(index, index + COLUMNS))
  }
  return chunks
})

const setWallpaper = (path: string) => {
  app.toggle_window(WALLPICKER_WINDOW)
  sh(`"$HOME/scripts/blob_wallpaper.sh" "${path}"`)
}

function Thumbnail({ wall }: { wall: Wallpaper }) {
  return (
    <button class="wall-thumb" onClicked={() => setWallpaper(wall.path)} tooltipText={wall.name}>
      <box
        class="wall-thumb-image"
        css={`background-image: url('${wall.path}');`}
      />
    </button>
  )
}

export default function WallPicker() {
  const hasWalls = wallpapers.as((list) => list.length > 0)
  const isEmpty = wallpapers.as((list) => list.length === 0)

  return (
    <window
      name={WALLPICKER_WINDOW}
      namespace={WALLPICKER_WINDOW}
      class="WallPicker"
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      exclusivity={Astal.Exclusivity.NORMAL}
      visible={false}
      application={app}
    >
      <box class="panel wall-picker" vertical spacing={12}>
        <box class="panel-header" spacing={8}>
          <label class="panel-title" label="Wallpapers" xalign={0} hexpand halign={Gtk.Align.START} />
          <button
            class="panel-icon-btn"
            tooltipText="Close"
            onClicked={() => app.toggle_window(WALLPICKER_WINDOW)}
          >
            <label label={""} />
          </button>
        </box>

        <scrollable
          class="wall-scroll"
          visible={hasWalls}
          hscroll={Gtk.PolicyType.NEVER}
          vscroll={Gtk.PolicyType.AUTOMATIC}
        >
          <box vertical spacing={8}>
            <For each={rows} id={(row: Wallpaper[]) => row.map((wall) => wall.name).join("|")}>
              {(row: Wallpaper[]) => (
                <box spacing={8} halign={Gtk.Align.CENTER}>
                  {row.map((wall) => (
                    <Thumbnail wall={wall} />
                  ))}
                </box>
              )}
            </For>
          </box>
        </scrollable>

        <box class="wall-empty" visible={isEmpty} vertical valign={Gtk.Align.CENTER}>
          <label class="wall-empty-icon" label={""} halign={Gtk.Align.CENTER} />
          <label class="wall-empty-text" label="No wallpapers in ~/wallpapers" halign={Gtk.Align.CENTER} />
        </box>
      </box>
    </window>
  )
}
