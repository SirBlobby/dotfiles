import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { sh, shell } from "../lib/utils"

export const NOTIFICATION_WINDOW = "notification-center"

type Notification = {
  file: string
  appName: string
  summary: string
  body: string
  timestamp: number
}

const NOTIFICATION_DIR = "$HOME/.local/state/omarchy/notifications"

const listCommand =
  `for file in "${NOTIFICATION_DIR}"/*.json "${NOTIFICATION_DIR}"/history/*.json; do ` +
  "[ -f \"$file\" ] || continue; " +
  "printf '%s\\t%s\\n' \"$file\" \"$(head -n 1 \"$file\")\"; " +
  "done"

function parseNotifications(stdout: string): Notification[] {
  return stdout
    .split("\n")
    .filter((line) => line.includes("\t"))
    .map((line) => {
      const separator = line.indexOf("\t")
      const file = line.slice(0, separator)
      try {
        const entry = JSON.parse(line.slice(separator + 1))
        return {
          file,
          appName: String(entry.app ?? ""),
          summary: String(entry.summary ?? ""),
          body: String(entry.body ?? ""),
          timestamp: Number(entry.timestamp ?? 0),
        }
      } catch {
        return null
      }
    })
    .filter((item): item is Notification => item !== null)
    .sort((left, right) => right.timestamp - left.timestamp)
}

const notifications = createPoll<Notification[]>(
  [],
  1000,
  shell(listCommand),
  (stdout) => parseNotifications(stdout),
)

const doNotDisturb = createPoll(
  false,
  1000,
  shell("omarchy-shell notifications dndState 2>/dev/null"),
  (stdout) => stdout.trim() === "on",
)

const dismiss = (file: string) => sh(`rm -f '${file.replace(/'/g, "'\\''")}'`)
const clearAll = () => sh("omarchy-shell notifications dismissAll; omarchy-shell notifications clear")
const toggleDoNotDisturb = () => sh("omarchy-shell notifications toggleDnd")

function NotificationItem({ item }: { item: Notification }) {
  return (
    <box class="notification-item" vertical>
      <box class="notification-item-header">
        <label
          class="notification-item-app"
          label={item.appName || "Notification"}
          xalign={0}
          halign={Gtk.Align.START}
          hexpand
        />
        <button
          class="notification-item-close"
          halign={Gtk.Align.END}
          onClicked={() => dismiss(item.file)}
        >
          <label label={""} />
        </button>
      </box>
      <label
        class="notification-item-summary"
        label={item.summary}
        xalign={0}
        halign={Gtk.Align.START}
        wrap
        maxWidthChars={34}
      />
      <label
        class="notification-item-body"
        visible={item.body.length > 0}
        label={item.body}
        xalign={0}
        halign={Gtk.Align.START}
        wrap
        maxWidthChars={34}
      />
    </box>
  )
}

export default function NotificationCenter() {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const hasNotifications = notifications.as((list) => list.length > 0)
  const isEmpty = notifications.as((list) => list.length === 0)

  return (
    <window
      name={NOTIFICATION_WINDOW}
      namespace={NOTIFICATION_WINDOW}
      class="NotificationCenter"
      anchor={TOP | RIGHT}
      margin={10}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.NORMAL}
      visible={false}
      application={app}
    >
      <box class="panel notification-center" vertical spacing={10}>
        <box class="panel-header" spacing={8}>
          <label class="panel-title" label="Notifications" xalign={0} hexpand halign={Gtk.Align.START} />
          <button
            class={doNotDisturb.as((on) => (on ? "panel-icon-btn active" : "panel-icon-btn"))}
            tooltipText="Do not disturb"
            onClicked={toggleDoNotDisturb}
          >
            <label label={doNotDisturb.as((on) => (on ? "" : ""))} />
          </button>
          <button class="panel-icon-btn" tooltipText="Clear all" onClicked={clearAll}>
            <label label={""} />
          </button>
        </box>

        <scrollable
          class="notification-scroll"
          visible={hasNotifications}
          vexpand
          hscroll={Gtk.PolicyType.NEVER}
          vscroll={Gtk.PolicyType.AUTOMATIC}
        >
          <box vertical spacing={8}>
            <For each={notifications} id={(item: Notification) => item.file}>
              {(item: Notification) => <NotificationItem item={item} />}
            </For>
          </box>
        </scrollable>

        <box class="notification-empty" visible={isEmpty} vertical valign={Gtk.Align.CENTER} vexpand>
          <label class="notification-empty-icon" label={""} halign={Gtk.Align.CENTER} />
          <label class="notification-empty-text" label="You're all caught up" halign={Gtk.Align.CENTER} />
        </box>
      </box>
    </window>
  )
}
