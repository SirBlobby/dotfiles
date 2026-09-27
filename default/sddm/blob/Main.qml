import QtQuick

Rectangle {
  id: root

  readonly property color backgroundColor: "#1a1b26"
  readonly property color textColor: "#ffffff"
  readonly property color errorColor: "#f7768e"
  readonly property string fontFamily: "monospace"

  readonly property color mutedTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.55)
  readonly property color faintTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18)
  readonly property color panelColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.04)

  property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
  property string statusMessage: ""
  property bool loggingIn: false

  width: 1920
  height: 1080

  gradient: Gradient {
    GradientStop { position: 0.0; color: root.backgroundColor }
    GradientStop { position: 1.0; color: Qt.darker(root.backgroundColor, 1.35) }
  }

  component LoginField: Item {
    id: field

    property string label: ""
    property bool hasError: false
    property bool isPassword: false
    property Item nextField: null
    property Item previousField: null
    property alias input: fieldInput
    property alias text: fieldInput.text

    signal submitted()

    width: 320
    height: 58

    Text {
      id: fieldLabel
      text: field.label.toUpperCase()
      color: fieldInput.activeFocus ? root.textColor : root.mutedTextColor
      font.family: root.fontFamily
      font.pixelSize: 11
      font.letterSpacing: 2
    }

    TextInput {
      id: fieldInput
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: fieldLabel.bottom
      anchors.topMargin: 10
      color: root.textColor
      selectionColor: root.faintTextColor
      echoMode: field.isPassword ? TextInput.Password : TextInput.Normal
      passwordCharacter: "•"
      font.family: root.fontFamily
      font.pixelSize: 18
      clip: true
      KeyNavigation.tab: field.nextField ? field.nextField.input : null
      KeyNavigation.backtab: field.previousField ? field.previousField.input : null
      Keys.onReturnPressed: field.submitted()
      Keys.onEnterPressed: field.submitted()
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: fieldInput.activeFocus || field.hasError ? 2 : 1
      color: field.hasError ? root.errorColor
        : fieldInput.activeFocus ? root.textColor
        : root.faintTextColor
    }
  }

  component FooterButton: Text {
    id: footerButton

    signal clicked()

    color: footerArea.containsMouse ? root.textColor : root.mutedTextColor
    font.family: root.fontFamily
    font.pixelSize: 12
    font.letterSpacing: 2

    MouseArea {
      id: footerArea
      anchors.fill: parent
      anchors.margins: -8
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: footerButton.clicked()
    }
  }

  function sessionName(index) {
    var session = sessionNames.itemAt(index)
    return session ? session.sessionName : ""
  }

  function nextSession() {
    if (sessionNames.count > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionNames.count
  }

  function login() {
    if (root.loggingIn) return
    if (usernameField.text.length === 0) {
      usernameField.input.forceActiveFocus()
      return
    }
    root.loggingIn = true
    root.statusMessage = ""
    sddm.login(usernameField.text, passwordField.text, root.sessionIndex)
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
      root.statusMessage = "Wrong password, try again"
      passwordField.text = ""
      passwordField.input.forceActiveFocus()
    }

    function onLoginSucceeded() {
      root.statusMessage = ""
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

  Column {
    anchors.centerIn: parent
    spacing: 48

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 4

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.now, "HH:mm")
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: 104
        font.weight: Font.Light
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.now, "dddd, MMMM d").toUpperCase()
        color: root.mutedTextColor
        font.family: root.fontFamily
        font.pixelSize: 14
        font.letterSpacing: 4
      }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 400
      height: loginColumn.implicitHeight + 80
      color: root.panelColor
      border.width: 1
      border.color: root.faintTextColor

      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: root.statusMessage.length > 0 ? root.errorColor : root.textColor
      }

      Column {
        id: loginColumn
        anchors.centerIn: parent
        spacing: 28

        Row {
          spacing: 16

          Image {
            id: logo
            width: 40
            height: 40
            source: "logo.png"
            sourceSize.width: 80
            sourceSize.height: 80
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
            onStatusChanged: if (status === Image.Error && source.toString().endsWith("logo.png")) source = "logo.svg"
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
              text: "Welcome back"
              color: root.textColor
              font.family: root.fontFamily
              font.pixelSize: 18
            }

            Text {
              text: "Sign in to continue"
              color: root.mutedTextColor
              font.family: root.fontFamily
              font.pixelSize: 12
            }
          }
        }

        LoginField {
          id: usernameField
          label: "Username"
          text: userModel.lastUser
          nextField: passwordField
          onSubmitted: passwordField.input.forceActiveFocus()
        }

        LoginField {
          id: passwordField
          label: "Password"
          hasError: root.statusMessage.length > 0
          isPassword: true
          previousField: usernameField
          onSubmitted: root.login()
        }

        Text {
          width: 320
          height: 16
          text: root.statusMessage.length > 0 ? root.statusMessage
            : root.loggingIn ? "Signing in..."
            : keyboard.capsLock ? "Caps Lock is on"
            : "Press Enter to sign in"
          color: root.statusMessage.length > 0 ? root.errorColor : root.mutedTextColor
          font.family: root.fontFamily
          font.pixelSize: 12
        }
      }
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 64
    color: root.panelColor

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: root.faintTextColor
    }

    FooterButton {
      anchors.left: parent.left
      anchors.leftMargin: 32
      anchors.verticalCenter: parent.verticalCenter
      text: "SESSION  " + root.sessionName(root.sessionIndex).toUpperCase()
      onClicked: root.nextSession()
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 32
      anchors.verticalCenter: parent.verticalCenter
      spacing: 32

      FooterButton {
        visible: sddm.canReboot
        text: "REBOOT"
        onClicked: sddm.reboot()
      }

      FooterButton {
        visible: sddm.canPowerOff
        text: "SHUT DOWN"
        onClicked: sddm.powerOff()
      }
    }
  }

  Component.onCompleted: {
    if (usernameField.text.length > 0) passwordField.input.forceActiveFocus()
    else usernameField.input.forceActiveFocus()
  }
}
