import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/Config"
import "root:/Widgets"

/*! One window inside an overview workspace card. */
Rectangle {
    id: root

    required property var toplevel

    signal activated()

    readonly property string windowClass: root.toplevel?.lastIpcObject?.class ?? ""
    readonly property string windowTitle: root.toplevel?.title ?? ""
    // Hyprland window selector. Quickshell may report the address
    // without its 0x prefix; the selector needs it.
    readonly property string selector: {
        const address = root.toplevel?.address ?? "";
        return "address:" + (address.startsWith("0x") ? address : "0x" + address);
    }

    /*! Match the window class to a desktop entry so we get a real icon. */
    readonly property string iconName: {
        if (!root.windowClass) return "";
        const wanted = root.windowClass.toLowerCase();
        for (const e of DesktopEntries.applications.values) {
            const id = e.id.replace(/\.desktop$/, "").toLowerCase();
            if (id === wanted || id.endsWith("." + wanted) || e.name.toLowerCase() === wanted)
                return e.icon;
        }
        return root.windowClass;   // let the icon theme try the raw class
    }

    implicitHeight: 30
    radius: Theme.radiusSm
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingXs
        anchors.rightMargin: Theme.spacingXs
        spacing: Theme.spacingSm

        AppIcon {
            size: 18
            source: root.iconName
            fallbackText: root.windowClass
        }

        StyledText {
            Layout.fillWidth: true
            text: root.windowTitle || root.windowClass
            font.pixelSize: Theme.fontSizeXs
            elide: Text.ElideRight
        }

        IconButton {
            icon: "󰅖"
            size: 18
            iconSize: Theme.fontSizeXs
            iconColor: Theme.faint
            onClicked: Hyprland.dispatch(`hl.dsp.window.close({ window = "${root.selector}" })`)
        }
    }

    StateLayer {
        radius: root.radius
        z: -1
        onClicked: {
            Hyprland.dispatch(`hl.dsp.focus({ window = "${root.selector}" })`);
            root.activated();
        }
    }
}
