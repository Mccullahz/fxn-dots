import QtQuick
import QtQuick.Layouts
import "root:/Config"
import "root:/Services"
import "root:/Widgets"

/*! Volume, microphone and brightness. */
ColumnLayout {
    spacing: Theme.spacingSm

    component SliderRow: RowLayout {
        id: srow

        property string glyph: ""
        property real level: 0
        property bool dim: false
        property string readout: ""

        signal moved(real v)
        signal glyphClicked()

        spacing: Theme.spacing

        IconButton {
            icon: srow.glyph
            size: 28
            iconColor: srow.dim ? Theme.faint : Theme.text
            onClicked: srow.glyphClicked()
        }

        StyledSlider {
            Layout.fillWidth: true
            value: srow.level
            fillColor: srow.dim ? Theme.faint : Theme.accent
            onMoved: v => srow.moved(v)
        }

        StyledText {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: srow.readout
            font.pixelSize: Theme.fontSizeXs
            color: Theme.faint
        }
    }

    SliderRow {
        Layout.fillWidth: true
        glyph: Audio.icon
        level: Audio.volume
        dim: Audio.muted
        readout: Math.round(Audio.volume * 100) + "%"
        onMoved: v => Audio.setVolume(v)
        onGlyphClicked: Audio.toggleMute()
    }

    SliderRow {
        Layout.fillWidth: true
        visible: Audio.sourceReady
        glyph: Audio.micIcon
        level: Audio.micVolume
        dim: Audio.micMuted
        readout: Math.round(Audio.micVolume * 100) + "%"
        onMoved: v => Audio.setMicVolume(v)
        onGlyphClicked: Audio.toggleMicMute()
    }

    SliderRow {
        Layout.fillWidth: true
        visible: Brightness.available
        glyph: Brightness.icon
        level: Brightness.value
        readout: Math.round(Brightness.value * 100) + "%"
        onMoved: v => Brightness.set(v)
    }
}
