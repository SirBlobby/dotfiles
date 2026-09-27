import QtQuick

Rectangle {
  id: root

  readonly property color backgroundColor: "#1a1b26"
  readonly property color textColor: "#ffffff"
  readonly property color errorColor: "#f7768e"
  readonly property string fontFamily: "monospace"

  property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
  property string statusMessage: ""
  property bool loggingIn: false

  width: 1920
  height: 1080
  color: root.backgroundColor

  function sessionName(index) {
    var session = sessionNames.itemAt(index)
    return session ? session.sessionName : ""
  }

  function nextSession() {
    if (sessionNames.count > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionNames.count
  }

  function login() {
    if (root.loggingIn) return
    if (usernameInput.text.length === 0) {
      usernameInput.forceActiveFocus()
      return
    }
    root.loggingIn = true
    root.statusMessage = ""
    sddm.login(usernameInput.text, passwordInput.text, root.sessionIndex)
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
      root.loggingIn = false
      root.statusMessage = "Wrong password"
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
    }

    function onLoginSucceeded() {
      root.statusMessage = ""
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 28

    Image {
      id: logo
      anchors.horizontalCenter: parent.horizontalCenter
      source: "logo.png"
      sourceSize.width: 160
      sourceSize.height: 160
      fillMode: Image.PreserveAspectFit
      onStatusChanged: if (status === Image.Error && source.toString().endsWith("logo.png")) source = "logo.svg"
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatTime(clock.now, "HH:mm")
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: 56
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Rectangle {
        width: 320
        height: 44
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: usernameInput.activeFocus ? root.textColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.35)

        TextInput {
          id: usernameInput
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          verticalAlignment: TextInput.AlignVCenter
          text: userModel.lastUser
          color: root.textColor
          font.family: root.fontFamily
          font.pixelSize: 16
          clip: true
          KeyNavigation.tab: passwordInput
          Keys.onReturnPressed: passwordInput.forceActiveFocus()
          Keys.onEnterPressed: passwordInput.forceActiveFocus()

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: usernameInput.text.length === 0
            text: "Username"
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
            font: usernameInput.font
          }
        }
      }

      Rectangle {
        width: 320
        height: 44
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: root.statusMessage.length > 0 ? root.errorColor
          : passwordInput.activeFocus ? root.textColor
          : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.35)

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "•"
          color: root.textColor
          font.family: root.fontFamily
          font.pixelSize: 16
          clip: true
          focus: usernameInput.text.length > 0
          KeyNavigation.backtab: usernameInput
          Keys.onReturnPressed: root.login()
          Keys.onEnterPressed: root.login()

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: passwordInput.text.length === 0
            text: root.loggingIn ? "Logging in..." : "Password"
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
            font.family: root.fontFamily
            font.pixelSize: 16
          }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        height: 20
        text: root.statusMessage
        color: root.errorColor
        font.family: root.fontFamily
        font.pixelSize: 14
      }
    }
  }

  Row {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 24

    Text {
      text: "Session: " + root.sessionName(root.sessionIndex)
      color: root.textColor
      opacity: sessionArea.containsMouse ? 1 : 0.6
      font.family: root.fontFamily
      font.pixelSize: 14

      MouseArea {
        id: sessionArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.nextSession()
      }
    }
  }

  Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 24
    spacing: 24

    Repeater {
      model: [
        { label: "Reboot", available: sddm.canReboot, action: "reboot" },
        { label: "Shut down", available: sddm.canPowerOff, action: "powerOff" }
      ]

      Text {
        required property var modelData
        visible: modelData.available
        text: modelData.label
        color: root.textColor
        opacity: powerArea.containsMouse ? 1 : 0.6
        font.family: root.fontFamily
        font.pixelSize: 14

        MouseArea {
          id: powerArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
        }
      }
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

  Component.onCompleted: {
    if (usernameInput.text.length > 0) passwordInput.forceActiveFocus()
    else usernameInput.forceActiveFocus()
  }
}
