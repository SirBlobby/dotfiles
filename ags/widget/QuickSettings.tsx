import app from "ags/gtk3/app"
import { Astal, Gdk, Gtk } from "ags/gtk3"
import { createState } from "ags"
import { createPoll, interval } from "ags/time"
import { sh, shell } from "../lib/utils"
import { ClaudeUsageCard } from "./ClaudeUsage"
import { CardHeader, StatRow } from "./WidgetCard"

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
  "omarchy-shell notifications dndState 2>/dev/null",
  2000,
)

const [nightLight, setNightLight] = pollBool(
  "omarchy-toggle-nightlight --status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off",
  2000,
)

const [stayAwake, setStayAwake] = pollBool(
  "omarchy-toggle-idle status 2>/dev/null | grep -q '\"enabled\":true' && echo on || echo off",
  2000,
)

const [recording] = pollBool(
  "pgrep -f '^gpu-screen-recorder' >/dev/null && echo on || echo off",
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
  tooltip,
  onClicked,
}: {
  icon: string
  label: string
  active?: any
  tooltip?: any
  onClicked: () => void
}) {
  return (
    <button
      class={active ? active.as((on: boolean) => (on ? "qs-tile active" : "qs-tile")) : "qs-tile"}
      tooltipText={tooltip ?? label}
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
        <Tile icon={""} label="Wi-Fi" onClicked={() => { closePanel(); sh("omarchy-shell shell toggle omarchy.network") }} />
        <Tile
          icon={""}
          label="Bluetooth"
          active={bluetoothOn}
          onClicked={() => {
            closePanel()
            sh("omarchy-shell shell toggle omarchy.bluetooth")
          }}
        />
        <Tile
          icon={""}
          label="Wallpaper"
          onClicked={() => {
            closePanel()
            sh("blob_wallpaper")
          }}
        />
      </box>
      <box class="qs-tiles" spacing={8} homogeneous>
        <Tile
          icon={""}
          label="Silence"
          active={doNotDisturb}
          onClicked={() => {
            setDoNotDisturb(!doNotDisturb.get())
            sh("omarchy-shell notifications toggleDnd")
          }}
        />
        <Tile
          icon={""}
          label="Night Light"
          active={nightLight}
          onClicked={() => {
            setNightLight(!nightLight.get())
            sh("omarchy-toggle-nightlight")
          }}
        />
        <Tile
          icon={""}
          label="Record"
          active={recording}
          tooltip={recording.as((on: boolean) => (on ? "Stop screen recording" : "Start a screen recording"))}
          onClicked={() => {
            closePanel()
            sh(recording.get()
              ? "omarchy-capture-screenrecording --stop-recording"
              : "omarchy-menu toggle trigger.capture.screenrecord")
          }}
        />
      </box>
      <box class="qs-tiles" spacing={8} homogeneous>
        <Tile
          icon={"󰅶"}
          label="Stay Awake"
          active={stayAwake}
          tooltip={stayAwake.as((on: boolean) => (on ? "Allow idle lock and screensaver" : "Keep the screen awake"))}
          onClicked={() => {
            setStayAwake(!stayAwake.get())
            sh("omarchy-toggle-idle toggle")
          }}
        />
        <Tile icon={""} label="Pick Color" onClicked={() => { closePanel(); sh("hyprpicker -a") }} />
        <Tile
          icon={""}
          label="Theme"
          onClicked={() => {
            closePanel()
            sh("blob_theme")
          }}
        />
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
        tooltipText={volume.as((level: number) => `Volume ${Math.round(level)}%`)}
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
        tooltipText={brightness.as((level: number) => `Brightness ${Math.round(level)}%`)}
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
          <button tooltipText="Previous track" onClicked={() => sh("playerctl previous")}>
            <label label={""} />
          </button>
          <button tooltipText="Play / pause" onClicked={() => sh("playerctl play-pause")}>
            <label label={media.as((m) => (m.status === "Playing" ? "" : ""))} />
          </button>
          <button tooltipText="Next track" onClicked={() => sh("playerctl next")}>
            <label label={""} />
          </button>
        </box>
      </box>
    </box>
  )
}

const [monthOffset, setMonthOffset] = createState(0)
const [monthName, setMonthName] = createState("")
const [monthGrid, setMonthGrid] = createState("")

const loadMonth = (offset: number) => {
  const firstOfMonth = `$(date +%Y-%m-01) ${offset} months`
  const command =
    `date -d "${firstOfMonth}" '+%B %Y'; ` +
    `cal $(date -d "${firstOfMonth}" '+%m %Y') | sed '1d'`

  sh(command).then((stdout) => {
    const lines = String(stdout).replace(/\s+$/, "").split("\n")
    setMonthName(lines[0]?.trim() ?? "")
    setMonthGrid(lines.slice(1).join("\n"))
  })
}

const shiftMonth = (delta: number) => {
  const next = monthOffset.get() + delta
  setMonthOffset(next)
  loadMonth(next)
}

const resetMonth = () => {
  setMonthOffset(0)
  loadMonth(0)
}

loadMonth(0)
interval(3600000, () => { if (monthOffset.get() === 0) loadMonth(0) })

function CalendarSection() {
  return (
    <eventbox
      onScroll={(_self: any, event: any) => {
        const direction = event?.direction
        const deltaY = Number(event?.delta_y ?? 0)
        if (direction === Gdk.ScrollDirection.UP || deltaY < 0) shiftMonth(-1)
        else if (direction === Gdk.ScrollDirection.DOWN || deltaY > 0) shiftMonth(1)
      }}
    >
      <box class="cc-calendar" vertical spacing={6}>
        <box class="cc-calendar-head" spacing={8}>
          <label
            class="cc-calendar-month"
            label={monthName}
            xalign={0}
            hexpand
            halign={Gtk.Align.START}
            tooltipText="Scroll to change month"
          />
          <button class="cc-calendar-nav" tooltipText="Previous month" onClicked={() => shiftMonth(-1)}>
            <label label={""} />
          </button>
          <button
            class="cc-calendar-nav"
            tooltipText="Back to this month"
            visible={monthOffset.as((offset) => offset !== 0)}
            onClicked={resetMonth}
          >
            <label label={""} />
          </button>
          <button class="cc-calendar-nav" tooltipText="Next month" onClicked={() => shiftMonth(1)}>
            <label label={""} />
          </button>
        </box>
        <label class="cc-calendar-grid" label={monthGrid} halign={Gtk.Align.CENTER} />
      </box>
    </eventbox>
  )
}

type Weather = { ok: boolean; icon: string; place: string; temp: string; wind: string }

function parseWeather(raw: string): Weather {
  const parts = raw.split("  ·  ")
  if (parts.length < 3) return { ok: false, icon: "", place: raw, temp: "", wind: "" }
  const match = parts[0].match(/^(\S+)\s*(.*)$/)
  return {
    ok: true,
    icon: match ? match[1] : "",
    place: match ? match[2].trim() : parts[0].trim(),
    temp: parts[1].replace(/^Temp\s*/, ""),
    wind: parts[2].replace(/^Wind\s*/, ""),
  }
}

const weather = createPoll<Weather>(
  { ok: false, icon: "", place: "Loading...", temp: "", wind: "" },
  600000,
  shell("bash $HOME/.config/ags/lib/weather.sh"),
  (stdout) => parseWeather(stdout.trim()),
)

function WeatherCard() {
  return (
    <box class="panel widget-card" vertical spacing={10}>
      <CardHeader icon={weather.as((w) => w.icon)} title={weather.as((w) => w.place)} />
      <label
        class="widget-card-empty"
        label="Weather unavailable"
        xalign={0}
        halign={Gtk.Align.START}
        visible={weather.as((w) => !w.ok)}
      />
      <box vertical spacing={8} visible={weather.as((w) => w.ok)}>
        <StatRow icon={""} label="Temperature" value={weather.as((w) => w.temp)} />
        <StatRow icon={""} label="Wind" value={weather.as((w) => w.wind)} />
      </box>
    </box>
  )
}

function LeftPanel() {
  return (
    <box class="qs-side-panel" vertical spacing={12} valign={Gtk.Align.START}>
      <WeatherCard />
    </box>
  )
}

function RightPanel() {
  return (
    <box class="qs-side-panel" vertical spacing={12} valign={Gtk.Align.START}>
      <ClaudeUsageCard />
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
      <box spacing={12}>
        <LeftPanel />
        <box class="panel quick-settings control-center" vertical spacing={12}>
          <Header />
          <CalendarSection />
          <Toggles />
          <VolumeSlider />
          <BrightnessSlider />
          <MediaPlayer />
        </box>
        <RightPanel />
      </box>
    </window>
  )
}
