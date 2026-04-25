import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

export default function Media(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT } = Astal.WindowAnchor

  const pollCmd = "playerctl metadata -f '{{title}}|||{{artist}}|||{{mpris:artUrl}}|||{{status}}|||{{mpris:length}}|||{{position}}' 2>/dev/null || echo 'No Media||||||Stopped|||0|||0'";

  const mediaState = createPoll({
    title: "No Media",
    artist: "",
    artUrl: "",
    status: "Stopped",
    length: 0,
    position: 0
  }, 1000, pollCmd, (stdout) => {
    const parts = stdout.split("|||");
    const title = parts[0]?.trim() || "No Media";
    const artist = parts[1]?.trim() || "";
    const rawUrl = parts[2]?.trim() || "";
    const artUrl = rawUrl.replace(/^file:\/\//, '');
    const status = parts[3]?.trim() || "Stopped";
    const length = Number(parts[4]) || 0;
    const position = Number(parts[5]) || 0;
    return { title, artist, artUrl, status, length, position };
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
      <box class="media-container" css="min-width: 350px;" spacing={15}>
        <box 
          class="media-cover" 
          css={mediaState.as(s => s.artUrl ? `background-image: url('${s.artUrl}'); min-width: 80px; min-height: 80px;` : 'min-width: 80px; min-height: 80px; background-color: alpha(@color0, 0.5);')}
        />
        
        <box vertical class="media-info-box" valign={Gtk.Align.CENTER} hexpand>
          <label 
            class="media-title" 
            label={mediaState.as(s => s.title)} 
            halign={Gtk.Align.FILL}
            xalign={0}
            truncate
            maxWidthChars={35}
            css="font-size: 15px;"
          />
          <label 
            class="media-artist" 
            label={mediaState.as(s => s.artist)} 
            halign={Gtk.Align.FILL}
            xalign={0}
            truncate
            maxWidthChars={40}
            css="font-size: 13px;"
          />

          <slider
            class="media-progress"
            drawValue={false}
            hexpand
            min={0}
            max={1}
            value={mediaState.as(s => {
              const len = s.length / 1000000;
              return len > 0 ? Math.min(s.position / len, 1) : 0;
            })}
            marginTop={10}
            marginBottom={10}
          />
          
          <box class="media-controls" spacing={15} halign={Gtk.Align.CENTER}>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl previous").catch(print)}
            >
              <label label="" css="font-size: 18px;" />
            </button>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl play-pause").catch(print)}
            >
              <label label={mediaState.as(s => s.status === "Playing" ? "" : "")} css="font-size: 22px;" />
            </button>
            <button
              class="media-btn"
              onClicked={() => execAsync("playerctl next").catch(print)}
            >
              <label label="" css="font-size: 18px;" />
            </button>
          </box>
        </box>
      </box>
    </window>
  )
}
