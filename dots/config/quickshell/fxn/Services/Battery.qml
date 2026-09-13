pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "root:/Config"

/*!
    The system's display battery, normalised for the bar and OSD.

    `available` is false on a desktop, and every widget that uses this
    service is expected to hide itself in that case.
*/
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice

    readonly property bool available: device?.isLaptopBattery ?? false
    readonly property real percent:   device?.percentage ?? 0      // 0..1
    readonly property bool onBattery: UPower.onBattery

    readonly property int  state:      device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging:   state === UPowerDeviceState.Charging
                                    || state === UPowerDeviceState.PendingCharge
    readonly property bool full:       state === UPowerDeviceState.FullyCharged

    /*! Seconds until empty (discharging) or full (charging); 0 if unknown. */
    readonly property real timeLeft: charging ? (device?.timeToFull ?? 0)
                                              : (device?.timeToEmpty ?? 0)

    readonly property real health: device?.healthPercentage ?? 0
    readonly property real rate:   Math.abs(device?.changeRate ?? 0)   // watts

    readonly property bool low:      available && !charging && percent <= 0.30
    readonly property bool critical: available && !charging && percent <= 0.15

    readonly property string icon: {
        if (charging) return "󰂄";
        if (full)     return "󰁹";
        const steps = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return steps[Math.max(0, Math.min(10, Math.round(percent * 10)))];
    }

    readonly property color tint: critical ? Theme.error
                                : low      ? Theme.warning
                                : charging ? Theme.success
                                           : Theme.text

    /*! "2h 14m", or "" when the estimate isn't ready yet. */
    readonly property string timeText: {
        if (timeLeft <= 0) return "";
        const h = Math.floor(timeLeft / 3600);
        const m = Math.floor((timeLeft % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    readonly property string statusText: {
        if (!available) return "";
        if (full)       return "Fully charged";
        const pct = Math.round(percent * 100) + "%";
        if (!timeText)  return pct;
        return charging ? `${pct} · ${timeText} until full`
                        : `${pct} · ${timeText} left`;
    }
}
