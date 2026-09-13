import QtQuick
import QtQuick.Effects
import "root:/Config"

/*! standard surface used by every panel. */
Rectangle {
    id: root

    property bool elevated: false

    color: Theme.surface
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: Theme.borderFaint

    layer.enabled: root.elevated
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadow
        shadowBlur: 0.6
        shadowVerticalOffset: 2
    }
}
