import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

export default function Media(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT } = Astal.WindowAnchor

  // Poll playerctl for complete metadata and status in one go
  const mediaState = createPoll({
    title: "No Media",
    artist: "",
    artUrl: "",
    status: "Stopped"
  }, 1000, "playerctl metadata -f '{{title}}|||{{artist}}|||{{mpris:artUrl}}|||{{status}}' 2>/dev/null || echo 'No Media||||||Stopped'", (stdout) => {
    const parts = stdout.split("|||");
    const title = parts[0]?.trim() || "No Media";
    const artist = parts[1]?.trim() || "";
    // GTK supports raw paths better than file:// URIs in background-image CSS
    const rawUrl = parts[2]?.trim() || "";
    const artUrl = rawUrl.replace(/^file:\/\//, '');
    const status = parts[3]?.trim() || "Stopped";
    return { title, artist, artUrl, status };
  });

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
      <box class="media-container" spacing={15}>
        <box 
          class="media-cover" 
          css={mediaState.as(s => s.artUrl ? `background-image: url('${s.artUrl}');` : 'background-color: alpha(@color0, 0.5);')}
        />
        
        <box vertical class="media-info-box" valign={Gtk.Align.CENTER}>
          <label 
            class="media-title" 
            label={mediaState.as(s => s.title)} 
            halign={Gtk.Align.START}
            truncate
            maxWidthChars={20}
          />
          <label 
            class="media-artist" 
            label={mediaState.as(s => s.artist)} 
            halign={Gtk.Align.START}
            truncate
            maxWidthChars={25}
          />
          
          <box class="media-controls" spacing={10} halign={Gtk.Align.START} marginTop={5}>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl previous").catch(print)}
            >
              <label label="" />
            </button>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl play-pause").catch(print)}
            >
              <label label={mediaState.as(s => s.status === "Playing" ? "" : "")} />
            </button>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl next").catch(print)}
            >
              <label label="" />
            </button>
          </box>
        </box>
      </box>
    </window>
  )
}
