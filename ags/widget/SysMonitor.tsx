import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { shell } from "../lib/utils"

export const SYSMONITOR_WINDOW = "sys-monitor"

let previousIdle = 0
let previousTotal = 0

const cpuUsage = createPoll(
  0,
  2000,
  shell("grep '^cpu ' /proc/stat"),
  (stdout) => {
    const values = stdout.trim().split(/\s+/).slice(1).map(Number)
    const idle = (values[3] || 0) + (values[4] || 0)
    const total = values.reduce((sum, value) => sum + value, 0)
    const idleDelta = idle - previousIdle
    const totalDelta = total - previousTotal
    previousIdle = idle
    previousTotal = total
    if (totalDelta <= 0) return 0
    return Math.round((1 - idleDelta / totalDelta) * 100)
  },
)

type Usage = { percent: number; used: string; total: string }

const memory = createPoll<Usage>(
  { percent: 0, used: "0", total: "0" },
  2000,
  shell("free -m | awk '/^Mem:/ {print $3\" \"$2}'"),
  (stdout) => {
    const [used, total] = stdout.trim().split(/\s+/).map(Number)
    if (!total) return { percent: 0, used: "0", total: "0" }
    return {
      percent: Math.round((used / total) * 100),
      used: `${(used / 1024).toFixed(1)}G`,
      total: `${(total / 1024).toFixed(1)}G`,
    }
  },
)

const disk = createPoll<Usage>(
  { percent: 0, used: "0", total: "0" },
  30000,
  shell("df -h --output=pcent,used,size / | tail -1"),
  (stdout) => {
    const [percent, used, total] = stdout.trim().split(/\s+/)
    return {
      percent: Number(percent.replace("%", "")) || 0,
      used: used || "0",
      total: total || "0",
    }
  },
)

const temperature = createPoll(
  0,
  2000,
  shell("cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"),
  (stdout) => Math.round(Number(stdout.trim()) / 1000) || 0,
)

function Metric({
  icon,
  name,
  percent,
  detail,
}: {
  icon: string
  name: string
  percent: any
  detail: any
}) {
  return (
    <box class="sys-metric" vertical spacing={4}>
      <box spacing={8}>
        <label class="sys-metric-icon" label={icon} />
        <label class="sys-metric-name" label={name} xalign={0} halign={Gtk.Align.START} hexpand />
        <label class="sys-metric-detail" label={detail} halign={Gtk.Align.END} />
      </box>
      <levelbar
        class="sys-metric-bar"
        value={percent.as((value: number) => value / 100)}
      />
    </box>
  )
}

export default function SysMonitor() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={SYSMONITOR_WINDOW}
      namespace={SYSMONITOR_WINDOW}
      class="SysMonitor"
      anchor={TOP | RIGHT}
      margin={10}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.NORMAL}
      visible={false}
      application={app}
    >
      <box class="panel sys-monitor" vertical spacing={12}>
        <label class="panel-title" label="System Monitor" xalign={0} halign={Gtk.Align.START} />

        <Metric
          icon={"\udb80\udf5b"}
          name="CPU"
          percent={cpuUsage}
          detail={cpuUsage.as((value) => `${value}%`)}
        />
        <Metric
          icon={"\udb81\ude1a"}
          name="Memory"
          percent={memory.as((value) => value.percent)}
          detail={memory.as((value) => `${value.used} / ${value.total}`)}
        />
        <Metric
          icon={"\udb80\udeca"}
          name="Disk"
          percent={disk.as((value) => value.percent)}
          detail={disk.as((value) => `${value.used} / ${value.total}`)}
        />
        <Metric
          icon={"\uf2c9"}
          name="Temperature"
          percent={temperature}
          detail={temperature.as((value) => `${value}°C`)}
        />
      </box>
    </window>
  )
}
