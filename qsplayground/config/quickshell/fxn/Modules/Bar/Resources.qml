import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    CPU and memory rings.

    subscribes to SysInfo only while it exists, so the /proc polling stops if the widget is ever taken out of the bar
*/
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: parent?.height ?? 28

    Component.onCompleted: SysInfo.subscribed++
    Component.onDestruction: SysInfo.subscribed--

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Ring {
            value: SysInfo.cpu
            icon: ""
            fillColor: SysInfo.cpu > 0.85 ? Theme.error
                     : SysInfo.cpu > 0.6  ? Theme.warning
                                          : Theme.accent
        }

        Ring {
            value: SysInfo.memory
            icon: ""
            fillColor: SysInfo.memory > 0.9 ? Theme.error
                     : SysInfo.memory > 0.7 ? Theme.warning
                                            : Theme.accentAlt
        }
    }

    StateLayer {
        id: state
        radius: Theme.radiusSm
        onClicked: Quickshell.execDetached([Settings.terminal, "-e", "btop"])
    }

    Tooltip {
        target: root
        hovered: state.containsMouse
        text: `CPU  ${Math.round(SysInfo.cpu * 100)}%` +
              (SysInfo.temperature > 0 ? `  ·  ${Math.round(SysInfo.temperature)}°C` : "") +
              `\nRAM  ${SysInfo.formatBytes(SysInfo.memUsedMb)} / ${SysInfo.formatBytes(SysInfo.memTotalMb)}` +
              `\nDisk ${Math.round(SysInfo.disk * 100)}%` +
              `\nUp   ${SysInfo.uptime}` +
              "\nClick to open btop"
    }
}
