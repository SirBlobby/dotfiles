import app from "ags/gtk3/app"
import { Astal, Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { sh, shell } from "../lib/utils"

export const NOTIFICATION_WINDOW = "notification-center"

type Notification = {
  id: number
  appName: string
  summary: string
  body: string
}

function parseNotifications(stdout: string): Notification[] {
  try {
    const parsed = JSON.parse(stdout)
    const group = parsed?.data?.[0] ?? []
    return group.map((item: any) => ({
      id: item.id?.value ?? 0,
      appName: item["app-name"]?.value ?? "",
      summary: item.summary?.value ?? "",
      body: item.body?.value ?? "",
    }))
  } catch {
    return []
  }
}

const notifications = createPoll<Notification[]>(
  [],
  1000,
  shell("makoctl list -j 2>/dev/null || echo '{}'"),
  (stdout) => parseNotifications(stdout),
)

const doNotDisturb = createPoll(
  false,
  1000,
  shell("makoctl mode 2>/dev/null"),
  (stdout) => stdout.split("\n").includes("do-not-disturb"),
)

const dismiss = (id: number) => sh(`makoctl dismiss -n ${id}`)
const clearAll = () => sh("makoctl dismiss -a")
const toggleDoNotDisturb = () => sh("makoctl mode -t do-not-disturb")

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
          onClicked={() => dismiss(item.id)}
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
            <For each={notifications} id={(item: Notification) => item.id}>
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
