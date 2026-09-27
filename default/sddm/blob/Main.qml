import QtQuick

Rectangle {
  id: root

  readonly property color backgroundColor: "#1a1b26"
  readonly property color textColor: "#ffffff"
  readonly property color errorColor: "#f7768e"
  readonly property string fontFamily: "monospace"

  readonly property color placeholderColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.66)
  readonly property color restingBorderColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.5)
  readonly property color fieldBackgroundColor: Qt.darker(backgroundColor, 1.25)

  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 2
  readonly property int fieldFontSize: 18
  readonly property int passwordDotFontSize: 21
  readonly property int passwordDotLetterSpacing: 3
  readonly property int clockFontSize: 72
  readonly property int dateFontSize: 18
  readonly property int smallFontSize: 14
  readonly property int sectionGap: 48
  readonly property int edgeMargin: 32

  property string username: userModel.lastUser
  property bool enteringUsername: username.length === 0
  property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
  property string failureMessage: ""
  property bool authenticating: false

  readonly property bool errorState: failureMessage.length > 0
  readonly property bool inputActive: fieldInput.text.length > 0 || authenticating
  readonly property string placeholderText: authenticating ? "Checking..."
    : errorState ? failureMessage
    : enteringUsername ? "Enter Username"
    : "Enter Password"

  width: 1920
  height: 1080
  color: backgroundColor

  function sessionName(index) {
    var session = sessionNames.itemAt(index)
    return session ? session.sessionName : ""
  }

  function nextSession() {
    if (sessionNames.count > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionNames.count
  }

  function changeUser() {
    root.failureMessage = ""
    root.enteringUsername = true
    fieldInput.text = root.username
    fieldInput.forceActiveFocus()
  }

  function submit() {
    var entered = fieldInput.text
    if (root.authenticating || entered.length === 0) return

    if (root.enteringUsername) {
      root.username = entered
      root.enteringUsername = false
      fieldInput.text = ""
      return
    }

    fieldInput.text = ""
    root.failureMessage = ""
    root.authenticating = true
    sddm.login(root.username, entered, root.sessionIndex)
  }

  Repeater {
    id: sessionNames
    model: sessionModel

    Item {
      required property string name
      readonly property string sessionName: name
    }
  }

  Connections {
    target: sddm

    function onLoginFailed() {
      root.authenticating = false
      root.failureMessage = "Wrong password"
      fieldInput.forceActiveFocus()
    }
  }

  QtObject {
    id: clock
    property date now: new Date()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.now = new Date()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: fieldInput.forceActiveFocus()
  }

  Image {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: clockColumn.top
    anchors.bottomMargin: root.sectionGap
    width: 96
    height: 96
    source: "logo.png"
    sourceSize.width: 192
    sourceSize.height: 192
    fillMode: Image.PreserveAspectFit
    onStatusChanged: if (status === Image.Error && source.toString().endsWith("logo.png")) source = "logo.svg"
  }

  Column {
    id: clockColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: usernameLabel.visible ? usernameLabel.top : inputField.top
    anchors.bottomMargin: root.sectionGap

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatTime(clock.now, "HH:mm")
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.clockFontSize
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(clock.now, "dddd, MMMM d")
      color: root.placeholderColor
      font.family: root.fontFamily
      font.pixelSize: root.dateFontSize
    }
  }

  Rectangle {
    id: inputField
    anchors.centerIn: parent
    width: root.fieldWidth
    height: root.fieldHeight
    color: root.fieldBackgroundColor
    border.width: root.outlineThickness
    border.color: root.errorState ? root.errorColor
      : root.inputActive ? root.textColor
      : root.restingBorderColor

    TextInput {
      id: fieldInput
      anchors.fill: parent
      anchors.margins: root.outlineThickness
      anchors.leftMargin: 18
      anchors.rightMargin: 18
      verticalAlignment: TextInput.AlignVCenter
      horizontalAlignment: TextInput.AlignHCenter
      clip: true
      focus: true
      readOnly: root.authenticating
      echoMode: root.enteringUsername ? TextInput.Normal : TextInput.Password
      passwordCharacter: "●"
      passwordMaskDelay: 0
      color: root.textColor
      selectionColor: root.restingBorderColor
      font.family: root.fontFamily
      font.pixelSize: text.length > 0 && !root.enteringUsername ? root.passwordDotFontSize : root.fieldFontSize
      font.letterSpacing: text.length > 0 && !root.enteringUsername ? root.passwordDotLetterSpacing : 0
      cursorDelegate: Rectangle {
        width: 2
        color: root.textColor
        visible: fieldInput.cursorVisible && fieldInput.text.length > 0
      }

      onTextChanged: if (text.length > 0) root.failureMessage = ""
      onAccepted: root.submit()

      Keys.onEscapePressed: text = ""
    }

    Text {
      anchors.fill: fieldInput
      visible: fieldInput.text.length === 0
      text: root.placeholderText
      color: root.authenticating ? root.textColor
        : root.errorState ? root.errorColor
        : root.placeholderColor
      font.family: root.fontFamily
      font.pixelSize: root.fieldFontSize
      font.italic: root.errorState
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
  }

  Text {
    id: usernameLabel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: inputField.top
    anchors.bottomMargin: 16
    visible: !root.enteringUsername
    text: root.username
    color: userArea.containsMouse ? root.textColor : root.placeholderColor
    font.family: root.fontFamily
    font.pixelSize: root.fieldFontSize

    MouseArea {
      id: userArea
      anchors.fill: parent
      anchors.margins: -8
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.changeUser()
    }
  }

  Text {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: root.edgeMargin
    text: root.sessionName(root.sessionIndex)
    color: sessionArea.containsMouse ? root.textColor : root.placeholderColor
    font.family: root.fontFamily
    font.pixelSize: root.smallFontSize

    MouseArea {
      id: sessionArea
      anchors.fill: parent
      anchors.margins: -8
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.nextSession()
    }
  }

  Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: root.edgeMargin
    spacing: 28

    Repeater {
      model: [
        { label: "Reboot", available: sddm.canReboot, action: "reboot" },
        { label: "Shut Down", available: sddm.canPowerOff, action: "powerOff" }
      ]

      Text {
        required property var modelData
        visible: modelData.available
        text: modelData.label
        color: powerArea.containsMouse ? root.textColor : root.placeholderColor
        font.family: root.fontFamily
        font.pixelSize: root.smallFontSize

        MouseArea {
          id: powerArea
          anchors.fill: parent
          anchors.margins: -8
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
        }
      }
    }
  }

  Component.onCompleted: fieldInput.forceActiveFocus()
}
