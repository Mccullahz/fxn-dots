pragma Singleton

import QtQuick
import Quickshell

/*!
    fs locations the shell reads and writes.
*/
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? "/tmp"

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string cacheHome:  Quickshell.env("XDG_CACHE_HOME")  || (home + "/.cache")
    readonly property string dataHome:   Quickshell.env("XDG_DATA_HOME")   || (home + "/.local/share")
    readonly property string stateHome:  Quickshell.env("XDG_STATE_HOME")  || (home + "/.local/state")

    /* this shell's config dir */
    readonly property string shell: configHome + "/quickshell/fxn"

    readonly property string theme:    shell + "/theme.json"
    readonly property string settings: shell + "/settings.json"
    readonly property string cache:            cacheHome + "/fxn"
    readonly property string wallpaperCache:   cache + "/wallpaper"
    readonly property string currentWallpaper: wallpaperCache + "/current"
    readonly property string hyprConfig: configHome + "/hypr"
    readonly property string hyprBin:    hyprConfig + "/bin"

    /* strip file:// prefix that QML dia add */
    function unUrl(path: string): string {
        return path.startsWith("file://") ? path.slice(7) : path;
    }
}
