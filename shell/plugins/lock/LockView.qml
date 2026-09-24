import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string brandingText: ""
  property string paletteColor4: ""
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

  readonly property string placeholderText: "Enter password"
  readonly property int fieldWidth: 360
  readonly property int fieldHeight: 52
  readonly property int outlineThickness: 2
  readonly property int fieldRadius: fieldHeight / 2
  readonly property int fieldSideInset: 20
  readonly property int fieldFontSize: Style.font.heading
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.2)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  readonly property int clockFontSize: Math.round(Style.font.display * 4)
  readonly property int dateFontSize: Math.round(Style.font.title * 1.4)
  readonly property int avatarSize: 72
  readonly property real iconReserve: Math.round(lockIcon.implicitWidth + 12)
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property int brandingMaxWidth: 700
  readonly property int brandingMaxFontSize: Math.round(Style.font.heading * 1.5)

  readonly property bool inputActive: passwordText.length > 0 || authenticatingPassword
  readonly property color accentColor: paletteColor4.length > 0 ? paletteColor4 : Color.accent
  readonly property color inputBorderColor: errorState
    ? Color.urgent
    : (inputActive || passwordInput.activeFocus ? root.accentColor : Util.alpha(Color.lock.text, 0.25))
  readonly property color inputBackground: Util.alpha(Color.background, 0.55)
  readonly property var inputBorderSpec: Border.flat(root.inputBorderColor, root.outlineThickness)

  readonly property string statusText: {
    if (root.authenticatingPassword) return "Checking…"
    if (root.errorState) {
      return root.failedAttempts > 1
        ? root.failureMessage + " (" + root.failedAttempts + " attempts)"
        : root.failureMessage
    }
    return root.fingerprintConfigured
      ? "Type your password or touch the fingerprint sensor"
      : "Type your password and press Enter"
  }

  property real shakeOffset: 0

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onFailureMessageChanged: if (failureMessage.length > 0) shakeAnimation.restart()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  SequentialAnimation {
    id: shakeAnimation
    NumberAnimation { target: root; property: "shakeOffset"; to: -14; duration: 50 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 12; duration: 70 }
    NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 60 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 5; duration: 50 }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 40 }
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: Util.alpha(Color.background, 0.2) }
        GradientStop { position: 0.5; color: Util.alpha(Color.background, 0.35) }
        GradientStop { position: 1.0; color: Util.alpha(Color.background, 0.7) }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      id: content
      anchors.centerIn: parent
      anchors.verticalCenterOffset: -Math.round(parent.height * 0.04)
      spacing: 0

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        textFormat: Text.PlainText
        color: Color.lock.text
        font.family: Style.font.family
        font.pixelSize: root.clockFontSize
        font.weight: Font.Light
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        textFormat: Text.PlainText
        color: Util.alpha(Color.lock.text, 0.8)
        font.family: Style.font.family
        font.pixelSize: root.dateFontSize
      }

      Item {
        width: 1
        height: Style.space(56)
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.avatarSize
        height: root.avatarSize
        radius: width / 2
        color: Util.alpha(root.accentColor, 0.22)
        border.width: root.outlineThickness
        border.color: root.accentColor

        Text {
          anchors.centerIn: parent
          text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : ""
          textFormat: Text.PlainText
          color: Color.lock.text
          font.family: Style.font.family
          font.pixelSize: Math.round(root.avatarSize * 0.42)
          font.bold: true
        }
      }

      Item {
        width: 1
        height: Style.space(12)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.userName
        visible: root.userName.length > 0
        textFormat: Text.PlainText
        color: Color.lock.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Item {
        width: 1
        height: Style.space(20)
      }

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fieldWidth
        height: root.fieldHeight

        BorderSurface {
          id: inputField
          width: parent.width
          height: parent.height
          x: root.shakeOffset
          color: root.inputBackground
          borderSpec: root.inputBorderSpec
          radius: root.fieldRadius
          clip: true

          Behavior on color {
            ColorAnimation { duration: 160 }
          }

          Text {
            id: lockIcon
            anchors.left: parent.left
            anchors.leftMargin: inputField.borderLeft + root.fieldSideInset
            anchors.verticalCenter: parent.verticalCenter
            text: root.errorState ? "" : ""
            textFormat: Text.PlainText
            color: root.errorState ? Color.lock.textError : Color.lock.placeholder
            font.family: Style.font.family
            font.pixelSize: Math.round(root.fieldFontSize * 1.05)
          }

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.topMargin: inputField.borderTop
            anchors.bottomMargin: inputField.borderBottom
            anchors.leftMargin: inputField.borderLeft + root.fieldSideInset + root.iconReserve
            anchors.rightMargin: inputField.borderRight + root.fieldSideInset + root.iconReserve
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            activeFocusOnPress: true
            clip: true
            enabled: root.inputEnabled && !root.authenticatingPassword
            readOnly: root.authenticatingPassword
            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: Color.lock.text
            selectionColor: Color.lock.selection
            selectedTextColor: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
            font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
            cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
            cursorDelegate: Rectangle {
              width: 2
              color: Color.lock.text
              visible: passwordInput.cursorVisible
            }

            onTextChanged: {
              if (!root.syncingPasswordText) root.passwordTextEdited(text)
              if (text.length > 0) root.wakeRequested()
              if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
            }

            onAccepted: {
              var submitted = root.passwordText
              root.passwordTextEdited("")
              if (submitted.length > 0) root.submitPassword(submitted)
            }

            Keys.onPressed: function(event) {
              root.wakeRequested()
              if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                root.passwordTextEdited("")
                event.accepted = true
              }
            }
          }

          Text {
            anchors.fill: passwordInput
            visible: passwordInput.text.length === 0
            text: root.authenticatingPassword ? "Checking…" : root.placeholderText
            textFormat: Text.PlainText
            color: Color.lock.placeholder
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          Text {
            id: fingerprintIcon
            objectName: "fingerprintIndicator"
            anchors.right: parent.right
            anchors.rightMargin: inputField.borderRight + root.fieldSideInset
            anchors.verticalCenter: parent.verticalCenter
            visible: root.fingerprintConfigured
            text: "󰈷"
            textFormat: Text.PlainText
            color: Color.lock.placeholder
            font.family: Style.font.family
            font.pixelSize: Math.round(root.fieldFontSize * 1.2)
          }
        }
      }

      Item {
        width: 1
        height: Style.space(14)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fieldWidth + Style.space(80)
        text: root.statusText
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: root.errorState ? Color.lock.textError : Util.alpha(Color.lock.text, 0.6)
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }
    }

    Text {
      id: branding
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(40)
      width: Math.min(parent.width * 0.6, root.brandingMaxWidth)
      height: Math.max(0, Math.min(parent.height * 0.18,
        parent.height - (content.y + content.height) - Style.space(80)))
      visible: root.brandingText.length > 0 && height > Style.space(24)
      opacity: 0.45
      text: root.brandingText
      textFormat: Text.PlainText
      color: Color.lock.text
      font.family: Style.font.family
      font.pixelSize: root.brandingMaxFontSize
      minimumPixelSize: 4
      fontSizeMode: Text.Fit
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignBottom
    }
  }
}
