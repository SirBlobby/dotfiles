import QtQuick
import qs.Commons
import "CalendarModel.js" as CalendarModel

Item {
  id: root

  required property var calendar

  readonly property var weeks: CalendarModel.monthGrid(calendar.viewYear, calendar.viewMonth,
    calendar.weekStart, calendar.todayKey, calendar.selectedKey)
  readonly property var weekdays: CalendarModel.weekdayOrder(calendar.weekStart)
  readonly property color foreground: calendar.foreground
  readonly property real headerHeight: Style.space(16)

  width: grid.width
  height: grid.height

  Column {
    id: grid
    spacing: Style.space(3)

    Row {
      id: headerRow
      spacing: root.calendar.cellSpacing

      Rectangle {
        visible: root.calendar.showWeekNumbers
        width: root.calendar.weekColumnWidth
        height: root.headerHeight
        radius: Style.cornerRadius
        color: weekHeaderMouse.containsMouse ? Style.hoverFillFor(root.foreground, Colors.accent) : "transparent"

        Text {
          anchors.centerIn: parent
          text: "W"
          color: weekHeaderMouse.containsMouse
            ? Style.hoverStateColor(root.foreground, Colors.accent)
            : Qt.darker(root.foreground, 1.9)
          font.family: root.calendar.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          font.bold: true
        }

        MouseArea {
          id: weekHeaderMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.calendar.weekHeaderClicked()
        }

        PanelToolTip {
          visible: weekHeaderMouse.containsMouse && root.calendar.weekHeaderTooltip !== ""
          text: root.calendar.weekHeaderTooltip
          fontFamily: root.calendar.fontFamily
        }
      }

      Item {
        visible: root.calendar.showWeekNumbers
        width: root.calendar.gutterWidth
        height: root.headerHeight
      }

      Repeater {
        model: root.weekdays

        Text {
          required property var modelData
          width: root.calendar.cellWidth
          height: root.headerHeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          textFormat: Text.PlainText
          text: root.calendar.weekdayLabel(modelData)
          color: root.calendar.mutedForeground
          font.family: root.calendar.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          font.bold: true
        }
      }
    }

    Repeater {
      model: root.weeks

      Row {
        required property var modelData
        spacing: root.calendar.cellSpacing

        Text {
          visible: root.calendar.showWeekNumbers
          width: root.calendar.weekColumnWidth
          height: root.calendar.cellHeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          textFormat: Text.PlainText
          text: modelData.week
          color: Qt.darker(root.foreground, 1.9)
          font.family: root.calendar.fontFamily
          font.pixelSize: Style.font.caption
        }

        Item {
          visible: root.calendar.showWeekNumbers
          width: root.calendar.gutterWidth
          height: root.calendar.cellHeight
        }

        Repeater {
          model: modelData.days

          DayCell {}
        }
      }
    }
  }

  Rectangle {
    visible: root.calendar.showWeekNumbers
    x: root.calendar.weekColumnWidth + root.calendar.cellSpacing
      + Math.round((root.calendar.gutterWidth - width) / 2)
    y: headerRow.height + grid.spacing
    width: Style.spacing.hairline
    height: grid.height - headerRow.height - grid.spacing
    color: root.foreground
    opacity: 0.1
  }

  component DayCell: Rectangle {
    id: cell

    required property var modelData

    readonly property color todayFill: Style.selectedStateColor(root.foreground, Colors.accent)
    readonly property color dayColor: {
      if (modelData.today) return Colors.background
      if (!modelData.inMonth) return root.foreground
      return modelData.weekend ? Qt.darker(root.foreground, 1.45) : root.foreground
    }

    width: root.calendar.cellWidth
    height: root.calendar.cellHeight
    radius: Style.cornerRadius
    color: {
      if (modelData.today) return todayFill
      if (dayMouse.containsMouse) return Style.hoverFillFor(root.foreground, Colors.accent)
      if (modelData.selected) return Style.selectedFillFor(root.foreground, Colors.accent)
      return "transparent"
    }
    border.width: modelData.selected && !modelData.today ? Math.max(1, Style.spacing.hairline) : 0
    border.color: Style.selectedBorderFor(root.foreground, Colors.accent)

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: cell.modelData.day
      color: cell.dayColor
      opacity: cell.modelData.inMonth || cell.modelData.today ? 1 : 0.3
      font.family: root.calendar.fontFamily
      font.pixelSize: Style.font.body
      font.bold: cell.modelData.today || cell.modelData.selected
    }

    MouseArea {
      id: dayMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.calendar.selectDay(cell.modelData.year, cell.modelData.month, cell.modelData.day)
    }
  }
}
