import app from "ags/gtk3/app"
import style from "./style.css"
import Media from "./widget/Media"

app.start({
  css: style,
  main() {
    app.get_monitors().map(Media)
  },
})