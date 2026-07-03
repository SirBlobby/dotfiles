import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createState } from "ags"
import { createPoll, interval } from "ags/time"
import { sh, shell } from "../lib/utils"

export const QUICKSETTINGS_WINDOW = "quick-settings"

const closePanel = () => app.toggle_window(QUICKSETTINGS_WINDOW)

function pollBool(command: string, intervalMs: number) {
  const [value, setValue] = createState(false)
  const refresh = () => sh(command).then((out) => setValue(out.trim() === "on"))
  refresh()
  interval(intervalMs, refresh)
  return [value, setValue] as const
}

const volume = createPoll(
  0,
  1000,
  shell("pamixer --get-volume 2>/dev/null || echo 0"),
  (stdout) => Number(stdout.trim()) || 0,
)

const [muted, setMuted] = pollBool(
  "pamixer --get-mute 2>/dev/null | grep -qx true && echo on || echo off",
  1000,
)

const brightness = createPoll(
  0,
  2000,
  shell("brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 0"),
  (stdout) => Number(stdout.trim()) || 0,
)

const [bluetoothOn] = pollBool(
  "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off",
  2000,
)

const [doNotDisturb, setDoNotDisturb] = pollBool(
  "makoctl mode 2>/dev/null | grep -qx do-not-disturb && echo on || echo off",
  2000,
)

const [nightLight, setNightLight] = pollBool(
  "pgrep -x hyprsunset >/dev/null && echo on || echo off",
  2000,
)

const clock = createPoll("", 1000, shell("date '+%H:%M'"), (stdout) => stdout.trim())
const today = createPoll("", 10000, shell("date '+%A, %B %-d'"), (stdout) => stdout.trim())

type Media = {
  title: string
  artist: string
  artUrl: string
  status: string
  length: number
  position: number
}

const mediaCommand =
  "playerctl metadata -f '{{title}}|||{{artist}}|||{{mpris:artUrl}}|||{{status}}|||{{mpris:length}}|||{{position}}' " +
  "2>/dev/null || echo 'No Media||||||Stopped|||0|||0'"

const media = createPoll<Media>(
  { title: "No Media", artist: "", artUrl: "", status: "Stopped", length: 0, position: 0 },
  1000,
  shell(mediaCommand),
  (stdout) => {
    const parts = stdout.split("|||")
    return {
      title: parts[0]?.trim() || "No Media",
      artist: parts[1]?.trim() || "",
      artUrl: (parts[2]?.trim() || "").replace(/^file:\/\//, ""),
      status: parts[3]?.trim() || "Stopped",
      length: Number(parts[4]) || 0,
      position: Number(parts[5]) || 0,
    }
  },
)

function Header() {
  return (
    <box class="cc-header" spacing={8}>
      <box class="cc-datetime" vertical hexpand halign={Gtk.Align.START}>
        <label class="cc-clock" label={clock} xalign={0} halign={Gtk.Align.START} />
        <label class="cc-date" label={today} xalign={0} halign={Gtk.Align.START} />
      </box>
      <button class="panel-icon-btn" tooltipText="Lock" onClicked={() => { closePanel(); sh("omarchy-system-lock") }}>
        <label label={""} />
      </button>
      <button class="panel-icon-btn" tooltipText="Log out" onClicked={() => { closePanel(); sh("omarchy-system-logout") }}>
        <label label={""} />
      </button>
      <button class="panel-icon-btn" tooltipText="Close" onClicked={closePanel}>
        <label label={"\uf00d"} />
      </button>
    </box>
  )
}

function Tile({
  icon,
  label,
  active,
  onClicked,
}: {
  icon: string
  label: string
  active?: any
  onClicked: () => void
}) {
  return (
    <button
      class={active ? active.as((on: boolean) => (on ? "qs-tile active" : "qs-tile")) : "qs-tile"}
      onClicked={onClicked}
      hexpand
    >
      <box vertical spacing={4} halign={Gtk.Align.CENTER}>
        <label class="qs-tile-icon" label={icon} />
        <label class="qs-tile-label" label={label} />
      </box>
    </button>
  )
}

function Toggles() {
  return (
    <box vertical spacing={8}>
      <box class="qs-tiles" spacing={8} homogeneous>
        <Tile icon={""} label="Wi-Fi" onClicked={() => { closePanel(); sh("omarchy-launch-wifi") }} />
        <Tile
          icon={""}
          label="Bluetooth"
          active={bluetoothOn}
          onClicked={() => {
            closePanel()
            sh("omarchy-launch-bluetooth")
          }}
        />
        <Tile
          icon={""}
          label="Silence"
          active={doNotDisturb}
          onClicked={() => {
            setDoNotDisturb(!doNotDisturb.get())
            sh("makoctl mode -t do-not-disturb")
          }}
        />
      </box>
      <box class="qs-tiles" spacing={8} homogeneous>
        <Tile
          icon={""}
          label="Night Light"
          active={nightLight}
          onClicked={() => {
            setNightLight(!nightLight.get())
            sh("omarchy-toggle-nightlight")
          }}
        />
        <Tile icon={""} label="Record" onClicked={() => { closePanel(); sh("omarchy-capture-screenrecording") }} />
        <Tile icon={""} label="Pick Color" onClicked={() => { closePanel(); sh("hyprpicker -a") }} />
      </box>
    </box>
  )
}

function VolumeSlider() {
  return (
    <box class="qs-slider-row" spacing={10}>
      <button
        class="qs-slider-icon"
        onClicked={() => {
          setMuted(!muted.get())
          sh("pamixer -t")
        }}
        tooltipText="Toggle mute"
      >
        <label label={muted.as((m) => (m ? "" : ""))} />
      </button>
      <slider
        class="qs-slider"
        hexpand
        min={0}
        max={100}
        step={1}
        value={volume}
        $={(self) => {
          self.connect("value-changed", () => {
            if (self.dragging) {
              sh(`pamixer --set-volume ${Math.round(self.value)}`)
            }
          })
        }}
      />
    </box>
  )
}

function BrightnessSlider() {
  return (
    <box class="qs-slider-row" spacing={10}>
      <label class="qs-slider-icon" label={""} />
      <slider
        class="qs-slider"
        hexpand
        min={1}
        max={100}
        step={1}
        value={brightness}
        $={(self) => {
          self.connect("value-changed", () => {
            if (self.dragging) {
              sh(`brightnessctl set ${Math.round(self.value)}%`)
            }
          })
        }}
      />
    </box>
  )
}

function MediaPlayer() {
  return (
    <box class="cc-media" spacing={12} visible={media.as((m) => m.title !== "No Media")}>
      <box
        class="cc-media-cover"
        css={media.as((m) =>
          m.artUrl
            ? `background-image: url('${m.artUrl}');`
            : "background-color: alpha(@color0, 0.5);",
        )}
      />
      <box class="cc-media-info" vertical valign={Gtk.Align.CENTER} hexpand>
        <label
          class="cc-media-title"
          label={media.as((m) => m.title)}
          xalign={0}
          halign={Gtk.Align.START}
          truncate
          maxWidthChars={22}
        />
        <label
          class="cc-media-artist"
          label={media.as((m) => m.artist)}
          xalign={0}
          halign={Gtk.Align.START}
          truncate
          maxWidthChars={26}
        />
        <slider
          class="cc-media-seek"
          hexpand
          min={0}
          max={1}
          step={0.01}
          value={media.as((m) => {
            const seconds = m.length / 1000000
            return seconds > 0 ? Math.min(m.position / seconds, 1) : 0
          })}
          $={(self) => {
            self.connect("value-changed", () => {
              if (self.dragging) {
                const seconds = media.get().length / 1000000
                sh(`playerctl position ${Math.round(self.value * seconds)}`)
              }
            })
          }}
        />
        <box class="cc-media-controls" spacing={14} halign={Gtk.Align.CENTER}>
          <button onClicked={() => sh("playerctl previous")}>
            <label label={""} />
          </button>
          <button onClicked={() => sh("playerctl play-pause")}>
            <label label={media.as((m) => (m.status === "Playing" ? "" : ""))} />
          </button>
          <button onClicked={() => sh("playerctl next")}>
            <label label={""} />
          </button>
        </box>
      </box>
    </box>
  )
}

const monthName = createPoll("", 60000, shell("date '+%B %Y'"), (stdout) => stdout.trim())
const monthGrid = createPoll(
  "",
  60000,
  shell("cal | sed '1d'"),
  (stdout) => stdout.replace(/\s+$/, ""),
)

function CalendarSection() {
  return (
    <box class="cc-calendar" vertical spacing={6}>
      <box class="cc-calendar-head" spacing={8}>
        <label class="cc-calendar-month" label={monthName} xalign={0} hexpand halign={Gtk.Align.START} />
      </box>
      <label class="cc-calendar-grid" label={monthGrid} halign={Gtk.Align.CENTER} />
    </box>
  )
}

export default function QuickSettings() {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      name={QUICKSETTINGS_WINDOW}
      namespace={QUICKSETTINGS_WINDOW}
      class="QuickSettings"
      anchor={TOP}
      margin={10}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.NORMAL}
      visible={false}
      application={app}
    >
      <box class="panel quick-settings control-center" vertical spacing={12}>
        <Header />
        <CalendarSection />
        <Toggles />
        <VolumeSlider />
        <BrightnessSlider />
        <MediaPlayer />
      </box>
    </window>
  )
}
