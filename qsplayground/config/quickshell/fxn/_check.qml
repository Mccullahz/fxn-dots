// temporary validation harness
// compiles every module without instantiating any layer-shell surface.
import QtQuick
import Quickshell
import "Modules/Bar"
import "Modules/Edge"
import "Modules/Osd"
import "Modules/Notifications"
import "Modules/ControlCenter"
import "Modules/Launcher"
import "Modules/PowerMenu"
import "Modules/Overview"
import "Modules/Cheatsheet"

ShellRoot {
    Component { Edge {} }
    Component { Bar {} }
    Component { Osd {} }
    Component { NotificationPopups {} }
    Component { ControlCenter {} }
    Component { Launcher {} }
    Component { PowerMenu {} }
    Component { Overview {} }
    Component { Cheatsheet {} }
    Ipc {}
}
