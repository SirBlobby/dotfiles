import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "blob.agents"
  ipcTarget: "blob.agents"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string barGlyph: "󱚣"
  readonly property string launchCommand: "blob-launch-terminal claude"

  readonly property var record: usage.record
  readonly property var windows: {
    var revision = usage.dataRevision
    return Model.displayWindows(record)
  }
  readonly property var phrases: {
    var revision = usage.dataRevision
    return Model.summaryPhrases(record)
  }
  readonly property bool alarming: {
    var fullest = Model.fullestWindow(record)
    return !!fullest && fullest.percent >= 0.9
  }

  property double nowMs: Date.now()
  property int phraseIndex: 0
  property string shownPhrase: ""

  function showPhrase() {
    shownPhrase = phrases.length > 0 ? phrases[phraseIndex % phrases.length] : ""
  }

  function launchAgent() {
    if (root.bar) root.bar.run(root.launchCommand)
    root.close()
  }

  onPhrasesChanged: if (shownPhrase === "" || phrases.length <= 1) showPhrase()

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    usage.refreshLimits()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Main {
    id: usage
    settings: root.settings
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  Timer {
    interval: 2800
    running: root.opened && root.phrases.length > 1
    repeat: true
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap

    PropertyAnimation {
      target: hero
      property: "metaOpacity"
      to: 0.0
      duration: 180
      easing.type: Easing.OutQuad
    }

    ScriptAction {
      script: {
        root.phraseIndex = (root.phraseIndex + 1) % Math.max(1, root.phrases.length)
        root.showPhrase()
      }
    }

    PropertyAnimation {
      target: hero
      property: "metaOpacity"
      to: 1.0
      duration: 260
      easing.type: Easing.InQuad
    }
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { usage.refresh() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barGlyph
    active: root.alarming

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.launchAgent()
      else if (mouseButton === Qt.MiddleButton) usage.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.launchAgent()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(key) { if (key === "r" || key === "R") usage.refresh() }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(16)

        PanelHero {
          id: hero
          width: parent.width
          title: "Claude Code"
          meta: root.shownPhrase !== "" ? root.shownPhrase : "Usage"
          detail: Model.planLabel(root.record)
          foreground: root.foreground
          fontFamily: root.fontFamily

          iconComponent: Component {
            ClaudeMark {
              size: Style.font.display
            }
          }

          trailingControl: Component {
            HeroButton {
              glyph: "󰞷"
              tooltip: "Start Claude Code"
              onClicked: root.launchAgent()
            }
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Text {
          visible: text !== ""
          width: parent.width
          textFormat: Text.PlainText
          text: Model.troubleText(root.record)
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Column {
          visible: root.windows.length > 0
          width: parent.width
          spacing: Style.space(12)

          Repeater {
            model: root.windows

            CompactLimit {
              required property var modelData
              width: column.width
              window: modelData
              stale: !!root.record && root.record.limitsStale === true
              fetchedAt: root.record ? Number(root.record.limitsFetchedAt || 0) : 0
            }
          }
        }

        Text {
          visible: !root.record
          width: parent.width
          text: "Loading usage..."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  component ClaudeMark: Item {
    id: mark
    property real size: Style.font.heading
    width: size
    height: size

    Image {
      id: markImage
      anchors.fill: parent
      source: Qt.resolvedUrl("assets/claude.svg")
      sourceSize.width: mark.size * 2
      sourceSize.height: mark.size * 2
      fillMode: Image.PreserveAspectFit
    }

    Text {
      anchors.centerIn: parent
      visible: markImage.status !== Image.Ready
      textFormat: Text.PlainText
      text: root.barGlyph
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: mark.size
    }
  }

  component HeroButton: Rectangle {
    id: heroButton
    signal clicked()
    property string glyph: ""
    property string tooltip: ""
    implicitWidth: Style.space(34)
    implicitHeight: implicitWidth
    radius: Style.cornerRadius
    color: Util.alpha(Color.accent, heroMouse.containsMouse ? 0.3 : 0.12)
    border.width: heroMouse.containsMouse ? Math.max(1, Style.hoverBorderWidth) : 0
    border.color: Color.accent

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: heroButton.glyph
      color: Color.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
    }

    MouseArea {
      id: heroMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: heroButton.clicked()
    }

    PanelToolTip {
      visible: heroMouse.containsMouse
      text: heroButton.tooltip
    }
  }

  component CompactLimit: Item {
    id: compact
    property var window: null
    property bool stale: false
    property real fetchedAt: 0
    readonly property real resetMs: Model.resetMillisecondsFor(window, root.nowMs)
    opacity: stale ? 0.5 : 1.0
    implicitHeight: Math.max(compactTitle.implicitHeight, compactValue.implicitHeight)

    HoverHandler { id: compactHover }

    PanelToolTip {
      visible: compactHover.hovered && !!compact.window
      text: Model.limitTooltip(compact.window, compact.stale, compact.fetchedAt, root.nowMs)
    }

    Text {
      id: compactTitle
      textFormat: Text.PlainText
      width: parent.width * 0.3
      anchors.verticalCenter: parent.verticalCenter
      text: compact.window ? compact.window.title : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Meter {
      anchors.left: compactTitle.right
      anchors.right: compactValue.left
      anchors.rightMargin: Style.space(20)
      anchors.verticalCenter: parent.verticalCenter
      value: compact.window ? compact.window.percent : -1
      alarming: !!compact.window && compact.window.percent >= 0.9
      markers: compact.window && compact.window.scoped ? compact.window.scoped : []
    }

    TextMetrics {
      id: compactValueMetrics
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      text: "00h 00m"
    }

    Text {
      id: compactValue
      width: Math.ceil(compactValueMetrics.advanceWidth)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignRight
      text: compact.resetMs > 0 ? Model.formatDuration(compact.resetMs) : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
    property var markers: []

    implicitHeight: thickness

    Rectangle {
      id: meterTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: meterTrack.left
      anchors.verticalCenter: meterTrack.verticalCenter
      height: meterTrack.height
      radius: meterTrack.radius
      width: meterTrack.width * Model.clamp(meter.value, 0, 1)
      color: meter.alarming ? root.urgent : root.foreground

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }

    Repeater {
      model: meter.markers

      Rectangle {
        required property var modelData
        width: Math.max(2, Math.round(meter.thickness * 0.5))
        height: meter.thickness * 2.5
        radius: width / 2
        anchors.verticalCenter: meterTrack.verticalCenter
        x: Model.clamp(meterTrack.width * Model.clamp(Number(modelData.percent), 0, 1) - width / 2, 0, meterTrack.width - width)
        color: meter.alarming ? root.urgent : root.foreground
      }
    }
  }
}
