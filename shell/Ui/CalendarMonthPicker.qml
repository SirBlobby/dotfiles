import QtQuick
import qs.Commons

Item {
  id: root

  required property var calendar

  readonly property int columns: 4
  readonly property int rows: 3
  readonly property real gap: calendar.cellSpacing * 2
  readonly property color foreground: calendar.foreground

  Grid {
    anchors.fill: parent
    columns: root.columns
    spacing: root.gap

    Repeater {
      model: 12

      Rectangle {
        id: monthCell

        required property int index

        readonly property bool isCurrentMonth: root.calendar.today.getFullYear() === root.calendar.pickerYear
          && root.calendar.today.getMonth() === index
        readonly property bool isViewedMonth: root.calendar.viewYear === root.calendar.pickerYear
          && root.calendar.viewMonth === index
        readonly property bool isCursor: root.calendar.pickerMonth === index

        width: (root.width - root.gap * (root.columns - 1)) / root.columns
        height: (root.height - root.gap * (root.rows - 1)) / root.rows
        radius: Style.cornerRadius
        color: {
          if (isCurrentMonth) return Style.selectedStateColor(root.foreground, Color.accent)
          if (isCursor) return Style.hoverFillFor(root.foreground, Color.accent)
          return "transparent"
        }
        border.width: isViewedMonth && !isCurrentMonth ? Math.max(1, Style.spacing.hairline) : 0
        border.color: Style.selectedBorderFor(root.foreground, Color.accent)

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.calendar.monthLabel(monthCell.index)
          color: monthCell.isCurrentMonth ? Color.background : root.foreground
          font.family: root.calendar.fontFamily
          font.pixelSize: Style.font.body
          font.letterSpacing: 1
          font.bold: monthCell.isCurrentMonth || monthCell.isViewedMonth
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onContainsMouseChanged: if (containsMouse) root.calendar.pickerMonth = monthCell.index
          onClicked: root.calendar.choosePickerMonth(root.calendar.pickerYear, monthCell.index)
        }
      }
    }
  }
}
