import { Gtk } from "ags/gtk3"

export function CardHeader({ icon, title }: { icon: any; title: any }) {
  return (
    <box class="widget-card-header" spacing={10}>
      <box class="widget-icon-badge">
        <label label={icon} />
      </box>
      <label class="widget-card-title" label={title} xalign={0} halign={Gtk.Align.START} hexpand />
    </box>
  )
}

export function StatRow({ icon, label, value }: { icon: string; label: string; value: any }) {
  return (
    <box class="widget-stat-row" spacing={8}>
      <label class="widget-stat-icon" label={icon} />
      <label class="widget-card-label" label={label} xalign={0} halign={Gtk.Align.START} hexpand />
      <label class="widget-card-value" label={value} />
    </box>
  )
}
