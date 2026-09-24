import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: root

  property var binding: null
  property var conflictLookup: null

  signal saveRequested(string keys, string description, string command)
  signal cancelRequested()

  readonly property var conflict: conflictLookup ? conflictLookup(keysField.text) : null
  readonly property bool canSave: keysField.text.trim().length > 0
    && descriptionField.text.trim().length > 0
    && commandField.text.trim().length > 0

  function load(source) {
    root.binding = source
    keysField.text = source ? source.keys : ""
    descriptionField.text = source ? source.description : ""
    commandField.text = source && source.kind === "exec" ? source.action : ""
    keysField.forceActiveFocus()
  }

  function save() {
    if (!root.canSave) return
    root.saveRequested(keysField.text.trim(), descriptionField.text.trim(), commandField.text.trim())
  }

  implicitHeight: form.implicitHeight + Style.spaceReal(24)
  radius: Style.cardRadius
  color: Util.alpha(Color.foreground, 0.06)
  border.width: 1
  border.color: Util.alpha(Color.accent, 0.6)

  Column {
    id: form
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.spaceReal(12)
    spacing: Style.spaceReal(8)

    Text {
      text: !root.binding ? "New binding"
        : (root.binding.origin === "personal" ? "Edit binding" : "Replace default binding")
      textFormat: Text.PlainText
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    TextField {
      id: keysField
      width: parent.width
      placeholderText: "Keys, e.g. SUPER + SHIFT + B"
      onAccepted: descriptionField.forceActiveFocus()
      Keys.onEscapePressed: root.cancelRequested()
    }

    TextField {
      id: descriptionField
      width: parent.width
      placeholderText: "Description, e.g. Browser"
      onAccepted: commandField.forceActiveFocus()
      Keys.onEscapePressed: root.cancelRequested()
    }

    TextField {
      id: commandField
      width: parent.width
      placeholderText: "Command, e.g. blob-launch-browser"
      onAccepted: root.save()
      Keys.onEscapePressed: root.cancelRequested()
    }

    Text {
      width: parent.width
      visible: root.conflict !== null
      wrapMode: Text.WordWrap
      text: !root.conflict ? ""
        : (root.conflict.origin === "personal"
            ? "Replaces your binding: " + root.conflict.description
            : "Disables the default: " + root.conflict.description)
      textFormat: Text.PlainText
      color: Color.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Flow {
      width: parent.width
      spacing: Style.spaceReal(6)

      Chip {
        label: "Save"
        active: root.canSave
        enabled: root.canSave
        onActivated: root.save()
      }

      Chip {
        label: "Cancel"
        onActivated: root.cancelRequested()
      }
    }
  }
}
