import app from "ags/gtk3/app"
import style from "./style.css"
import Media from "./widget/Media"
import NotificationCenter from "./widget/Notifications"
import QuickSettings from "./widget/QuickSettings"
import SysMonitor from "./widget/SysMonitor"
import WallPicker from "./widget/WallPicker"

const SHOW_DESKTOP_MEDIA = false

function start(name: string, build: () => unknown) {
  try {
    build()
  } catch (error) {
    console.error(`Failed to start widget "${name}":`, error)
  }
}

app.start({
  css: style,
  main() {
    if (SHOW_DESKTOP_MEDIA) {
      app.get_monitors().map(Media)
    }
    start("notification-center", NotificationCenter)
    start("quick-settings", QuickSettings)
    start("sys-monitor", SysMonitor)
    start("wall-picker", WallPicker)
  },
})
