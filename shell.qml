import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        anchors {
            top: calendar.anchorCorner.startsWith("top-")
            bottom: calendar.anchorCorner.startsWith("bottom-")
            left: calendar.anchorCorner.endsWith("-left")
            right: calendar.anchorCorner.endsWith("-right")
        }
        margins {
            top: calendar.anchorCorner.startsWith("top-") ? calendar.offsetY : 0
            bottom: calendar.anchorCorner.startsWith("bottom-") ? calendar.offsetY : 0
            left: calendar.anchorCorner.endsWith("-left") ? calendar.offsetX : 0
            right: calendar.anchorCorner.endsWith("-right") ? calendar.offsetX : 0
        }

        implicitWidth: calendar.implicitWidth
        implicitHeight: calendar.implicitHeight
        color: "transparent"
        WlrLayershell.keyboardFocus: calendar.editorOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Calendar {
            id: calendar
            anchors.fill: parent
            isLarge: false
        }
    }
}