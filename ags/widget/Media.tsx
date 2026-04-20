import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

export default function Media(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT } = Astal.WindowAnchor

  // Poll playerctl for metadata and status
  const mediaInfo = createPoll("No Media Playing", 1000, 'sh -c "playerctl metadata -f \'{{title}} - {{artist}}\' 2>/dev/null || echo \'No Media Playing\'"')
  const statusIcon = createPoll("▶", 1000, 'sh -c "s=\\$(playerctl status 2>/dev/null); if [ \\"\\$s\\" = \\"Playing\\" ]; then echo \\"⏸\\"; else echo \\"▶\\"; fi"')

  return (
    <window
      class="MediaWindow"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.BOTTOM}
      anchor={TOP | LEFT}
      margin={20}
      application={app}
    >
      <box class="media-container" spacing={10}>
        <button
          class="media-btn"
          onClicked={() => execAsync("playerctl previous").catch(print)}
          halign={Gtk.Align.CENTER}
        >
          <label label="⏮" />
        </button>
        <button
          class="media-btn"
          onClicked={() => execAsync("playerctl play-pause").catch(print)}
          halign={Gtk.Align.CENTER}
        >
          <label label={statusIcon} />
        </button>
        <button
          class="media-btn"
          onClicked={() => execAsync("playerctl next").catch(print)}
          halign={Gtk.Align.CENTER}
        >
          <label label="⏭" />
        </button>
        <label class="media-text" label={mediaInfo} />
      </box>
    </window>
  )
}