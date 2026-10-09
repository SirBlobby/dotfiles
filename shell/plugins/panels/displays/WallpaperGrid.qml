import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property string directory: Quickshell.env("HOME") + "/wallpapers"
  property string assignedPath: ""
  property bool polling: false
  property var wallpapers: []

  signal chosen(string path)

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  Process {
    id: listProc
    command: ["bash", "-c",
      'find -L "$1" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" ' +
      '-o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) | sort',
      "--", root.directory]
    stdout: StdioCollector {
      onStreamFinished: {
        var out = []
        var lines = String(text).split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (line.length > 0) out.push(line)
        }
        root.wallpapers = out
      }
    }
  }

  onPollingChanged: if (root.polling && root.wallpapers.length === 0) root.refresh()
  Component.onCompleted: root.refresh()

  GridView {
    id: grid
    anchors.fill: parent
    clip: true
    readonly property int columnCount: Math.max(1, Math.floor(width / Style.spaceReal(120)))
    cellWidth: width / columnCount
    cellHeight: cellWidth * 2 / 3
    model: root.wallpapers

    delegate: Item {
      required property var modelData
      width: grid.cellWidth
      height: grid.cellHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: Style.spaceReal(3)
        radius: Style.cardRadius
        color: Util.alpha(Colors.background, Style.cardFillAlpha)
        border.width: Style.cardBorderWidth
        border.color: modelData === root.assignedPath
          ? Colors.accent
          : (hover.hovered ? Colors.blue : Util.alpha(Colors.blue, Style.cardBorderAlpha))
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: Style.cardBorderWidth
          source: Util.fileUrl(modelData)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          sourceSize.width: Math.round(grid.cellWidth * 1.5)
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: Style.cardBorderWidth
          height: caption.implicitHeight + Style.spaceReal(4)
          visible: hover.hovered || modelData === root.assignedPath
          color: Util.alpha(Colors.background, 0.8)

          Text {
            id: caption
            anchors.centerIn: parent
            width: parent.width - Style.spaceReal(6)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            text: String(modelData).replace(/^.*\//, "")
            textFormat: Text.PlainText
            color: Colors.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        HoverHandler {
          id: hover
        }

        TapHandler {
          onTapped: root.chosen(String(modelData))
        }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.wallpapers.length === 0
    text: "No images in " + root.directory
    textFormat: Text.PlainText
    color: Util.alpha(Colors.foreground, 0.6)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}
