import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string brandingPath: home + "/.config/omarchy/branding/screensaver.txt"
  readonly property string palettePath: home + "/.local/state/omarchy/current/theme/colors.toml"

  property string brandingText: ""
  property string paletteColor4: ""

  function readPaletteColor4(raw) {
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*color4\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (match) return match[1]
    }
    return ""
  }

  FileView {
    path: root.brandingPath
    watchChanges: true
    printErrors: false
    onLoaded: root.brandingText = text()
    onLoadFailed: root.brandingText = ""
    onFileChanged: reload()
  }

  FileView {
    path: root.palettePath
    watchChanges: true
    printErrors: false
    onLoaded: root.paletteColor4 = root.readPaletteColor4(text())
    onLoadFailed: root.paletteColor4 = ""
    onFileChanged: reload()
  }
}
