import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "KeybindsModel.js" as KeybindsModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: (manifest && manifest.id) || "blob.keybinds"

  property var bindings: []
  property string searchText: ""
  property string filterMode: "all"
  property string statusText: ""
  property bool statusIsError: false
  property bool editorOpen: false

  readonly property var visibleBindings: KeybindsModel.filterBindings(root.bindings, root.searchText, root.filterMode)

  function open(payloadJson) {
    root.opened = true
    root.refresh()
    Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function close() {
    root.opened = false
    root.editorOpen = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  function runChange(args, successMessage) {
    if (changeProc.running) return
    root.statusText = ""
    root.statusIsError = false
    changeProc.successMessage = successMessage
    changeProc.command = ["blob-keybinds"].concat(args)
    changeProc.running = true
  }

  function openEditor(binding) {
    root.editorOpen = true
    editor.load(binding)
  }

  function saveBinding(keys, description, command) {
    var args = ["add", keys, description, command]
    var editing = editor.binding
    if (editing && editing.origin === "personal" && editing.canonical !== KeybindsModel.canonicalKeys(keys))
      args.push(editing.keys)
    root.runChange(args, "Saved " + keys)
    root.editorOpen = false
  }

  function conflictFor(keys) {
    return KeybindsModel.conflictFor(root.bindings, keys, editor.binding)
  }

  Process {
    id: listProc
    command: ["blob-keybinds", "list"]
    stdout: StdioCollector {
      onStreamFinished: root.bindings = KeybindsModel.parseBindings(text)
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim().length === 0) return
        root.statusText = text.trim()
        root.statusIsError = true
      }
    }
  }

  Process {
    id: changeProc
    property string successMessage: ""
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim().length === 0) return
        root.statusText = text.trim()
        root.statusIsError = true
      }
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.statusText = changeProc.successMessage
        root.statusIsError = false
      } else if (root.statusText.length === 0) {
        root.statusText = "The change could not be saved"
        root.statusIsError = true
      }
      root.refresh()
    }
  }

  PanelWindow {
    id: panelWindow
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "blob-keybinds"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    MouseArea {
      anchors.fill: card
    }

    Card {
      id: card

      readonly property real screenMargin: Style.spaceReal(20)

      anchors.centerIn: parent
      implicitWidth: Math.min(Style.spaceReal(760), panelWindow.width - screenMargin * 2)
      implicitHeight: Math.min(Style.spaceReal(640), panelWindow.height - screenMargin * 2)
      fillColor: Util.alpha(Colors.background, Style.panelFillAlpha)
      spacing: Style.spaceReal(10)

      KeybindsHeader {
        id: header
        width: parent.width
        onAddRequested: root.openEditor(null)
        onCloseRequested: root.dismiss()
      }

      TextField {
        id: searchField
        width: parent.width
        placeholderText: "Search keys, descriptions or commands"
        onTextChanged: root.searchText = text
        Keys.onEscapePressed: root.dismiss()
      }

      Flow {
        id: filters
        width: parent.width
        spacing: Style.spaceReal(4)

        Chip {
          label: "All"
          active: root.filterMode === "all"
          onActivated: root.filterMode = "all"
        }

        Chip {
          label: "Mine"
          active: root.filterMode === "personal"
          onActivated: root.filterMode = "personal"
        }

        Chip {
          label: "Disabled or replaced"
          active: root.filterMode === "changed"
          onActivated: root.filterMode = "changed"
        }
      }

      KeybindEditor {
        id: editor
        width: parent.width
        visible: root.editorOpen
        conflictLookup: root.conflictFor
        onSaveRequested: function(keys, description, command) { root.saveBinding(keys, description, command) }
        onCancelRequested: root.editorOpen = false
      }

      ListView {
        id: list
        width: parent.width
        height: Math.max(Style.spaceReal(80), card.height - card.padding * 2 - y - status.height - card.spacing)
        clip: true
        spacing: Style.spaceReal(4)
        boundsBehavior: Flickable.StopAtBounds
        model: root.visibleBindings

        delegate: KeybindRow {
          required property var modelData
          width: ListView.view.width
          binding: modelData
          onEditRequested: root.openEditor(modelData)
          onResetRequested: root.runChange(["reset", modelData.keys],
            modelData.origin === "personal" ? "Removed " + modelData.keys : "Restored " + modelData.keys)
          onDisableRequested: root.runChange(["disable", modelData.keys], "Disabled " + modelData.keys)
        }
      }

      Text {
        id: status
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.statusText.length > 0 ? root.statusText
          : root.visibleBindings.length + " bindings. Changes go to ~/.config/hypr/bindings.lua and Hyprland reloads."
        textFormat: Text.PlainText
        color: root.statusIsError ? Colors.urgent : Util.alpha(Colors.foreground, 0.6)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
