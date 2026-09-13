import QtQuick
import "root:/Config"

/*! progress ring — used for CPU, memory and disk readouts. */
Item {
    id: root

    property real value: 0
    property int  thickness: 3
    property color trackColor: Theme.alpha(Theme.foreground, 0.15)
    property color fillColor: Theme.accent
    property string icon: ""

    implicitWidth: 26
    implicitHeight: 26

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const r = Math.min(width, height) / 2 - root.thickness / 2;
            const cx = width / 2, cy = height / 2;
            const start = -Math.PI / 2;

            ctx.reset();
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.strokeStyle = root.trackColor;
            ctx.stroke();

            const v = Math.max(0, Math.min(1, root.value));
            if (v > 0) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, start, start + Math.PI * 2 * v);
                ctx.strokeStyle = root.fillColor;
                ctx.stroke();
            }
        }
    }

    onValueChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Icon {
        anchors.centerIn: parent
        visible: root.icon !== ""
        text: root.icon
        size: Math.round(root.height * 0.42)
        color: root.fillColor
    }
}
