import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! Live calculator output for the launcher's `=` mode. */
Item {
    id: root

    property string expression: ""

    implicitHeight: visible ? column.implicitHeight + Theme.spacingXl * 2 : 0

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        width: parent.width - Theme.spacingXl * 2
        spacing: Theme.spacingSm

        StyledText {
            Layout.fillWidth: true
            text: root.expression || "…"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.subtext
            font.pixelSize: Theme.fontSizeSm
            elide: Text.ElideMiddle
        }

        StyledText {
            Layout.fillWidth: true
            text: Calc.error ? "—" : (Calc.result || "…")
            horizontalAlignment: Text.AlignHCenter
            color: Calc.error ? Theme.faint : Theme.accent
            font.pixelSize: Theme.fontSizeHuge
            font.bold: true
            elide: Text.ElideMiddle
        }

        StyledText {
            Layout.fillWidth: true
            visible: Calc.result !== "" && !Calc.error
            text: "↵ to copy"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.faint
            font.pixelSize: Theme.fontSizeXs
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Calc.qalcAvailable
            text: "qalc not installed — using the basic evaluator"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.warning
            font.pixelSize: Theme.fontSizeXs
        }
    }
}
