import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*!
    wallpaper picker
*/
Card {
    id: root

    required property bool shown
    required property int duration

    property string filter: ""
    property int columns: 3

    signal done()

    readonly property var shownItems: Wallpapers.query(root.filter, 300)
    property int selected: 0

    implicitHeight: layout.implicitHeight + Theme.spacing * 2

    color: Theme.panel
    border.color: Theme.border
    radius: Theme.radius
    elevated: true
    clip: true

    transformOrigin: Item.Top
    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.97
    transform: Translate { y: root.shown ? 0 : -14 }
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: Math.round(root.duration * 0.7) }
    }
    Behavior on scale {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
    }

    onShownChanged: {
        if (!root.shown) return;
        if (Wallpapers.theme === Themes.current) Wallpapers.refresh();
        else Wallpapers.theme = Themes.current;
    }
    onShownItemsChanged: root.selectCurrent()

    function selectCurrent(): void {
        const i = root.shownItems.findIndex(w => w.path === Wallpapers.current);
        root.selected = i >= 0 ? i : 0;
        grid.positionViewAtIndex(root.selected, GridView.Contain);
    }

    function navigate(dx: int, dy: int): void {
        const n = root.shownItems.length;
        if (n === 0) return;
        root.selected = Math.max(0, Math.min(n - 1, root.selected + dx + dy * root.columns));
        grid.positionViewAtIndex(root.selected, GridView.Contain);
    }

    function activate(): void {
        const w = root.shownItems[root.selected];
        if (!w) return;
        Wallpapers.apply(w.path);
        root.done();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.spacing
        spacing: Theme.spacingSm

        // ─── Themes ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            Repeater {
                model: Themes.list

                delegate: Rectangle {
                    id: tab

                    required property var modelData

                    readonly property bool active: tab.modelData.name === Themes.current

                    implicitWidth: tabLabel.implicitWidth + Theme.spacing * 2
                    implicitHeight: 26
                    radius: height / 2
                    color: tab.active ? Theme.alpha(Theme.accent, 0.22) : "transparent"
                    border.width: tab.active ? 0 : 1
                    border.color: Theme.borderFaint

                    Behavior on color {
                        ColorAnimation { duration: Theme.durNormal }
                    }

                    StyledText {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tab.modelData.label
                        font.pixelSize: Theme.fontSizeSm
                        color: tab.active ? Theme.accent : Theme.subtext
                    }

                    StateLayer {
                        radius: tab.radius
                        enabled: !Themes.busy
                        onClicked: {
                            Wallpapers.theme = tab.modelData.name;
                            Themes.apply(tab.modelData.name);
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: Themes.busy
                text: "applying…"
                font.pixelSize: Theme.fontSizeXs
                color: Theme.faint
            }
        }

        // ─── Thumbnails ─────────────────────────────────────
        GridView {
            id: grid

            readonly property int rows: Math.ceil(root.shownItems.length / root.columns)

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(rows, 3) * cellHeight
            visible: root.shownItems.length > 0

            cellWidth: Math.floor((root.width - Theme.spacing * 2) / root.columns)
            cellHeight: Math.round(cellWidth * 9 / 16) + 20
            model: root.shownItems
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: cellHeight * 2

            delegate: Item {
                id: cell

                required property int index
                required property var modelData

                readonly property bool selected: cell.index === root.selected
                readonly property bool isCurrent: cell.modelData.path === Wallpapers.current

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    id: frame
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    height: width * 9 / 16
                    radius: Theme.radiusSm
                    color: Theme.surface
                    border.width: cell.selected ? 2 : cell.isCurrent ? 1 : 0
                    border.color: cell.selected ? Theme.accent : Theme.accentAlt
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: frame.border.width
                        source: "file://" + cell.modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 256
                        sourceSize.height: 144
                    }
                }

                StyledText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    text: cell.modelData.name
                    font.pixelSize: Theme.fontSizeXs
                    color: cell.selected ? Theme.text : Theme.faint
                    elide: Text.ElideRight
                }

                StateLayer {
                    radius: Theme.radiusSm
                    showState: false
                    onContainsMouseChanged: if (containsMouse) root.selected = cell.index
                    onClicked: {
                        root.selected = cell.index;
                        Wallpapers.apply(cell.modelData.path);
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingLg
            visible: root.shownItems.length === 0
            text: Wallpapers.scanning ? "Loading…"
                : root.filter ? "No matches"
                : "No wallpapers for this theme yet — run fxn-walls fetch"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.faint
            font.pixelSize: Theme.fontSizeSm
        }
    }
}
