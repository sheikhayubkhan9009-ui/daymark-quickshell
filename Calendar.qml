import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io

Item {
    id: root

    Settings {
        id: calendarPreferences
        location: Qt.resolvedUrl("daymark-settings.ini")
        property int themeIndex: 0
        property string anchorCorner: "top-right"
        property int offsetX: 0
        property int offsetY: 90
        property bool behindWindows: false
        property string calendarSource: ""
    }

    property bool isLarge: false
    property bool settingsOpen: false
    property bool positionLocked: true
    property alias themeIndex: calendarPreferences.themeIndex
    property alias anchorCorner: calendarPreferences.anchorCorner
    property alias offsetX: calendarPreferences.offsetX
    property alias offsetY: calendarPreferences.offsetY
    property alias behindWindows: calendarPreferences.behindWindows
    property alias calendarSource: calendarPreferences.calendarSource
    property real themePulse: 0.3
    property var themes: [
        { name: "Nebula", bg: "#171522", panel: "#28233a", accent: "#c4a7e7", text: "#f0eaff", muted: "#aaa0bf", event: "#ff83b7", shadow: "#090810" },
        { name: "Deep Ocean", bg: "#0c2028", panel: "#163945", accent: "#65d9df", text: "#e7fcff", muted: "#90b7bf", event: "#ffbd69", shadow: "#061217" },
        { name: "Moss", bg: "#17221b", panel: "#29392c", accent: "#a8d5a2", text: "#eff8e9", muted: "#a4b5a0", event: "#f0bd73", shadow: "#09100b" },
        { name: "Afterglow", bg: "#2b1820", panel: "#482630", accent: "#ffad78", text: "#fff0df", muted: "#c4a2a3", event: "#ff7297", shadow: "#10080c" },
        { name: "Citrus", bg: "#202515", panel: "#37421f", accent: "#d3ed67", text: "#f6f8dc", muted: "#b2bd84", event: "#ff9b69", shadow: "#0d1008" },
        { name: "Rose Glass", bg: "#281722", panel: "#45283c", accent: "#ff9fce", text: "#fff0f7", muted: "#c5a1b6", event: "#f6d365", shadow: "#10080e" },
        { name: "Arctic", bg: "#17242d", panel: "#283a48", accent: "#9bd8ff", text: "#edf8ff", muted: "#a4bac9", event: "#ffc77d", shadow: "#080f14" },
        { name: "Copper", bg: "#281b17", panel: "#493027", accent: "#f0a978", text: "#fff1e5", muted: "#c5a18d", event: "#e8d27a", shadow: "#100a07" },
        { name: "Electric", bg: "#161d2a", panel: "#252e43", accent: "#80f0c0", text: "#effff8", muted: "#9dbab3", event: "#ff88ad", shadow: "#080b12" },
        { name: "Monochrome", bg: "#1c1d20", panel: "#33363b", accent: "#e5e7eb", text: "#f7f7f8", muted: "#aaadb4", event: "#ff9e7a", shadow: "#090a0b" }
    ]
    readonly property var currentTheme: themes[themeIndex]
    property var events: ({})
    property var sharedEvents: ({})
    property var feedEvents: ({})
    property date currentDate: new Date()
    property int displayYear: currentDate.getFullYear()
    property int displayMonth: currentDate.getMonth()
    property bool followsCurrentMonth: true
    property date selectedDate: currentDate
    property string hoveredDateKey: ""
    property var eventTimes: ({})
    property var sharedEventTimes: ({})
    property var feedEventTimes: ({})
    property var reminderSent: ({})
    property bool editorOpen: false
    property string editorError: ""
    property string feedStatus: "No calendar connected"
    property string notificationMessage: ""
    property bool notificationPending: false
    property var notificationQueue: []
    property string activeWidget: "none"
    readonly property string focusPath: Quickshell.env("XDG_RUNTIME_DIR") + "/daymark-widget-focus"
    readonly property string sharedEventsDir: Quickshell.env("HOME") + "/.local/share/qs-notes"
    readonly property string sharedEventsPath: sharedEventsDir + "/calendar-events.json"
    readonly property bool widgetExpanded: isLarge || settingsOpen || editorOpen
    readonly property bool selectedEventIsLocal: sharedEvents[dateKey(selectedDate)] !== undefined
                                                  && sharedEvents[dateKey(selectedDate)] === events[dateKey(selectedDate)]

    onIsLargeChanged: syncWidgetFocus()
    onSettingsOpenChanged: syncWidgetFocus()
    onEditorOpenChanged: syncWidgetFocus()
    onActiveWidgetChanged: {
        if (activeWidget === "none" && widgetExpanded) syncWidgetFocus()
        else if (activeWidget === "calendar" && !widgetExpanded) syncWidgetFocus()
    }

    Component.onCompleted: {
        if (positionLocked) {
            anchorCorner = "top-right"
            offsetX = 0
            offsetY = 98
        }
        if (calendarSource.trim())
            Qt.callLater(function() { root.refreshCalendarSource() })
    }

    implicitWidth: settingsOpen ? 220 : (editorOpen ? 240 : (isLarge ? 240 : 112.2))
    implicitHeight: settingsOpen ? 310 : (editorOpen ? 300 : (isLarge ? 280 : 76.5))

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    SequentialAnimation on themePulse {
        loops: Animation.Infinite
        NumberAnimation { from: 0.35; to: 1.0; duration: 1300; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.35; duration: 1300; easing.type: Easing.InOutSine }
    }

    function dateKey(date) {
        var month = String(date.getMonth() + 1).padStart(2, "0")
        var day = String(date.getDate()).padStart(2, "0")
        return date.getFullYear() + "-" + month + "-" + day
    }

    function rebuildCalendarEvents() {
        events = Object.assign({}, feedEvents, sharedEvents)
        eventTimes = Object.assign({}, feedEventTimes, sharedEventTimes)
    }

    function unescapeIcs(value) {
        return String(value).replace(/\\[nN]/g, "\n")
                             .replace(/\\([,;\\])/g, "$1")
    }

    function parseIcsStart(value) {
        var dateMatch = /^(\d{4})(\d{2})(\d{2})$/.exec(value)
        if (dateMatch) {
            var allDay = new Date(Number(dateMatch[1]), Number(dateMatch[2]) - 1, Number(dateMatch[3]))
            if (allDay.getFullYear() !== Number(dateMatch[1]) || allDay.getMonth() !== Number(dateMatch[2]) - 1 || allDay.getDate() !== Number(dateMatch[3]))
                return null
            return { date: dateKey(allDay), time: "00:00" }
        }

        var timeMatch = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})?(Z)?$/.exec(value)
        if (!timeMatch) return null
        var year = Number(timeMatch[1])
        var month = Number(timeMatch[2]) - 1
        var day = Number(timeMatch[3])
        var hour = Number(timeMatch[4])
        var minute = Number(timeMatch[5])
        var second = Number(timeMatch[6] || 0)
        var parsed = timeMatch[7]
            ? new Date(Date.UTC(year, month, day, hour, minute, second))
            : new Date(year, month, day, hour, minute, second)
        if (!timeMatch[7] && (parsed.getFullYear() !== year || parsed.getMonth() !== month || parsed.getDate() !== day || hour > 23 || minute > 59))
            return null
        function two(number) { return number < 10 ? "0" + number : String(number) }
        return { date: dateKey(parsed), time: two(parsed.getHours()) + ":" + two(parsed.getMinutes()) }
    }

    function parseICalendar(data) {
        var lines = String(data).replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "").split(/\r?\n/)
        var importedEvents = ({})
        var importedTimes = ({})
        var current = null

        for (var index = 0; index < lines.length; index++) {
            var line = lines[index]
            if (line === "BEGIN:VEVENT") {
                current = {}
                continue
            }
            if (line === "END:VEVENT" && current) {
                var start = parseIcsStart(current.start || "")
                if (start) {
                    var title = unescapeIcs(current.summary || "Calendar event")
                    importedEvents[start.date] = importedEvents[start.date]
                        ? importedEvents[start.date] + " · " + title : title
                    if (!importedTimes[start.date] || start.time < importedTimes[start.date])
                        importedTimes[start.date] = start.time
                }
                current = null
                continue
            }
            if (!current) continue

            var separator = line.indexOf(":")
            if (separator < 0) continue
            var property = line.substring(0, separator).split(";")[0].toUpperCase()
            var value = line.substring(separator + 1)
            if (property === "DTSTART") current.start = value
            else if (property === "SUMMARY") current.summary = value
        }

        feedEvents = importedEvents
        feedEventTimes = importedTimes
        rebuildCalendarEvents()
        var count = Object.keys(importedEvents).length
        feedStatus = count ? "Loaded " + count + " event dates" : "No events found in source"
        console.info("Calendar feed test:", feedStatus)
    }

    function refreshCalendarSource() {
        var source = calendarSource.trim()
        if (!source) {
            feedEvents = ({})
            feedEventTimes = ({})
            rebuildCalendarEvents()
            feedStatus = "No calendar connected"
            return
        }

        if (calendarFeedProcess.running) calendarFeedProcess.running = false
        if (source.indexOf("webcal://") === 0)
            source = "https://" + source.substring(9)

        if (source.indexOf("http://") === 0 || source.indexOf("https://") === 0) {
            calendarFeedProcess.command = ["curl", "--fail", "--silent", "--show-error", "--location", "--max-time", "25", source]
        } else {
            if (source.indexOf("file://") === 0) source = decodeURIComponent(source.substring(7))
            if (source.indexOf("~/") === 0) source = Quickshell.env("HOME") + source.substring(1)
            calendarFeedProcess.command = ["cat", source]
        }

        feedStatus = "Syncing calendar..."
        calendarFeedProcess.running = true
    }

    function compactEventSummary() {
        var todayKey = dateKey(currentDate)
        if (events[todayKey])
            return events[todayKey]

        var now = new Date()
        var nextKey = ""
        var nextTime = Infinity
        for (var key in events) {
            var dateParts = key.split("-")
            var timeParts = (eventTimes[key] || "23:59").split(":")
            var eventDate = new Date(Number(dateParts[0]), Number(dateParts[1]) - 1,
                                     Number(dateParts[2]), Number(timeParts[0]), Number(timeParts[1]))
            if (eventDate >= now && eventDate.getTime() < nextTime) {
                nextKey = key
                nextTime = eventDate.getTime()
            }
        }

        if (!nextKey)
            return "No event today"
        var nextDate = new Date(nextKey + "T00:00:00")
        return Qt.formatDate(nextDate, "MMM d") + ": " + events[nextKey]
    }

    function cycleTheme() {
        themeIndex = (themeIndex + 1) % themes.length
    }

    function syncWidgetFocus() {
        if (widgetExpanded) {
            focusFile.setText("calendar")
            activeWidget = "calendar"
        } else if (activeWidget === "calendar") {
            focusFile.setText("none")
            activeWidget = "none"
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.sharedEventsDir]
    }

    FileView {
        id: focusFile
        path: root.focusPath
        watchChanges: true
        onLoaded: {
            var value = text().trim() || "none"
            if (root.activeWidget !== value) root.activeWidget = value
            if (value === "calendar" && !root.widgetExpanded) root.syncWidgetFocus()
            if (value === "none" && root.widgetExpanded) root.syncWidgetFocus()
        }
        onFileChanged: focusReloadTimer.restart()
    }

    Timer {
        id: focusReloadTimer
        interval: 100
        onTriggered: focusFile.reload()
    }

    FileView {
        id: sharedEventsFile
        path: root.sharedEventsPath
        watchChanges: true
        onLoaded: {
            try {
                var data = JSON.parse(text())
                root.sharedEvents = data.events || {}
                root.sharedEventTimes = data.eventTimes || {}
                root.rebuildCalendarEvents()
                root.checkReminders()
            } catch (e) {}
        }
        onFileChanged: sharedEventsReloadTimer.restart()
    }

    Timer {
        id: sharedEventsReloadTimer
        interval: 100
        onTriggered: sharedEventsFile.reload()
    }

    function shiftMonth(amount) {
        followsCurrentMonth = false
        var nextMonth = new Date(displayYear, displayMonth + amount, 1)
        displayYear = nextMonth.getFullYear()
        displayMonth = nextMonth.getMonth()
    }

    function selectDate(date) {
        selectedDate = date
        displayYear = date.getFullYear()
        displayMonth = date.getMonth()
        followsCurrentMonth = date.getFullYear() === currentDate.getFullYear()
                              && date.getMonth() === currentDate.getMonth()
    }

    function goToToday() {
        currentDate = new Date()
        selectedDate = currentDate
        displayYear = currentDate.getFullYear()
        displayMonth = currentDate.getMonth()
        followsCurrentMonth = true
    }

    function refreshCurrentDate() {
        var previousKey = dateKey(currentDate)
        var today = new Date()
        currentDate = today

        if (followsCurrentMonth) {
            displayYear = today.getFullYear()
            displayMonth = today.getMonth()
            if (dateKey(selectedDate) === previousKey)
                selectedDate = today
        }
    }

    function openEventEditor(date) {
        selectDate(date)
        var key = dateKey(date)
        eventTitleInput.text = events[key] || ""
        eventTimeInput.text = eventTimes[key] || "09:00"
        editorError = ""
        editorOpen = true
    }

    function saveEvent() {
        var title = eventTitleInput.text.trim()
        var time = eventTimeInput.text
        var timeMatch = /^([01][0-9]|2[0-3]):([0-5][0-9])$/.exec(time)

        if (!title) {
            editorError = "Enter an event name."
            return
        }
        if (!timeMatch) {
            editorError = "Enter a time in 24-hour format."
            return
        }

        var key = dateKey(selectedDate)
        var updatedEvents = Object.assign({}, sharedEvents)
        updatedEvents[key] = title
        sharedEvents = updatedEvents

        var updatedTimes = Object.assign({}, sharedEventTimes)
        updatedTimes[key] = time
        sharedEventTimes = updatedTimes
        rebuildCalendarEvents()
        sharedEventsFile.setText(JSON.stringify({ events: sharedEvents, eventTimes: sharedEventTimes }))

        var updatedReminders = Object.assign({}, reminderSent)
        delete updatedReminders[key]
        reminderSent = updatedReminders
        editorOpen = false
        checkReminders()
    }

    function deleteEvent() {
        var key = dateKey(selectedDate)
        if (!selectedEventIsLocal) return

        var updatedEvents = Object.assign({}, sharedEvents)
        var updatedTimes = Object.assign({}, sharedEventTimes)
        delete updatedEvents[key]
        delete updatedTimes[key]
        sharedEvents = updatedEvents
        sharedEventTimes = updatedTimes
        rebuildCalendarEvents()
        sharedEventsFile.setText(JSON.stringify({ events: sharedEvents, eventTimes: sharedEventTimes }))

        var updatedReminders = Object.assign({}, reminderSent)
        delete updatedReminders[key]
        reminderSent = updatedReminders
        editorOpen = false
        editorError = ""
    }

    function queueNotification(message) {
        var updatedQueue = notificationQueue.slice()
        updatedQueue.push(message)
        notificationQueue = updatedQueue
        root.dispatchNotification()
    }

    function dispatchNotification() {
        if (notificationPending || notificationQueue.length === 0)
            return

        var updatedQueue = notificationQueue.slice()
        notificationMessage = updatedQueue.shift()
        notificationQueue = updatedQueue
        notificationPending = true
    }

    function checkReminders() {
        var now = new Date()
        var updatedReminders = Object.assign({}, reminderSent)
        var changed = false

        for (var key in events) {
            var timeMatch = /^([01][0-9]|2[0-3]):([0-5][0-9])$/.exec(eventTimes[key] || "")
            if (!timeMatch)
                continue

            var dateParts = key.split("-")
            var eventDate = new Date(Number(dateParts[0]), Number(dateParts[1]) - 1,
                                     Number(dateParts[2]), Number(timeMatch[1]), Number(timeMatch[2]))
            var reminderStage = Number(updatedReminders[key] || 0)

            if (reminderStage < 1 && now >= eventDate) {
                updatedReminders[key] = 1
                changed = true
                root.queueNotification(events[key] + " is scheduled for now (" + Qt.formatTime(eventDate, "HH:mm") + ").")
            } else if (reminderStage < 2 && now >= new Date(eventDate.getTime() + 5 * 60 * 1000)) {
                updatedReminders[key] = 2
                changed = true
                root.queueNotification("Follow-up: " + events[key] + " started 5 minutes ago.")
            }
        }

        if (changed)
            reminderSent = updatedReminders
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.settingsOpen
        color: root.currentTheme.bg
        border.color: Qt.darker(root.currentTheme.accent, 2.2)
        border.width: 1
        radius: 2

        Behavior on color { ColorAnimation { duration: 420; easing.type: Easing.InOutCubic } }
        Behavior on border.color { ColorAnimation { duration: 420 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.isLarge ? 10 : 3
            spacing: root.isLarge ? 6 : 0

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.isLarge
                spacing: 2

                Rectangle {
                    id: compactDate
                    Layout.preferredWidth: 26
                    Layout.fillHeight: true
                    radius: 7
                    color: root.currentTheme.panel
                    y: compactDateMouse.pressed ? 2 : 0
                    scale: compactDateMouse.pressed ? 0.94 : (compactDateMouse.containsMouse ? 1.03 : 1)

                    Behavior on y { NumberAnimation { duration: 90 } }
                    Behavior on scale { SpringAnimation { spring: 3; damping: 0.35 } }
                    Behavior on color { ColorAnimation { duration: 420 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDate(root.currentDate, "MMM").toUpperCase()
                            color: root.currentTheme.accent
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.currentDate.getDate()
                            color: root.currentTheme.text
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: compactDateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.isLarge = true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDate(new Date(root.displayYear, root.displayMonth, 1), "MMM yyyy")
                        color: root.currentTheme.text
                        font.pixelSize: 8
                        font.bold: true
                        elide: Text.ElideRight

                        Behavior on color { ColorAnimation { duration: 420 } }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.compactEventSummary()
                        color: root.currentTheme.muted
                        font.pixelSize: 7
                        elide: Text.ElideRight

                        Behavior on color { ColorAnimation { duration: 420 } }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        radius: 1
                        color: root.currentTheme.accent
                        opacity: root.themePulse

                        Behavior on color { ColorAnimation { duration: 420 } }
                    }
                }

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 16
                    spacing: 2

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "+"
                        fontSize: 12
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        shadowColor: root.currentTheme.shadow
                        onClicked: root.isLarge = true
                    }

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.behindWindows ? "T" : "B"
                        fontSize: 9
                        highlighted: root.behindWindows
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        shadowColor: root.currentTheme.shadow
                        onClicked: root.behindWindows = !root.behindWindows
                    }

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "S"
                        fontSize: 9
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        shadowColor: root.currentTheme.shadow
                        onClicked: root.settingsOpen = true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.isLarge
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: Qt.formatDate(new Date(root.displayYear, root.displayMonth, 1), "MMMM yyyy")
                    color: root.currentTheme.text
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 420 } }
                }

                DepthButton {
                    implicitWidth: 20
                    implicitHeight: 20
                    text: "‹"
                    fontSize: root.isLarge ? 18 : 15
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    textColor: root.currentTheme.text
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.shiftMonth(-1)
                }

                DepthButton {
                    implicitWidth: 20
                    implicitHeight: 20
                    text: "›"
                    fontSize: root.isLarge ? 18 : 15
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    textColor: root.currentTheme.text
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.shiftMonth(1)
                }

                DepthButton {
                    implicitWidth: 16
                    implicitHeight: 20
                    text: "-"
                    fontSize: 12
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.isLarge = false
                }

                DepthButton {
                    implicitWidth: 28
                    implicitHeight: 20
                    text: "Now"
                    fontSize: 8
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.goToToday()
                }

                DepthButton {
                    implicitWidth: 16
                    implicitHeight: 20
                    text: "S"
                    fontSize: 9
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: {
                        root.isLarge = false
                        root.settingsOpen = true
                    }
                }

                DepthButton {
                    implicitWidth: 20
                    implicitHeight: 20
                    text: root.behindWindows ? "T" : "B"
                    fontSize: 9
                    highlighted: root.behindWindows
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.behindWindows = !root.behindWindows
                }
            }

            GridLayout {
                Layout.fillWidth: true
                visible: root.isLarge
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: root.currentTheme.muted
                        font.pixelSize: root.isLarge ? 12 : 10
                        font.bold: true
                    }
                }
            }

            GridLayout {
                id: daysGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isLarge
                columns: 7
                rows: 6
                rowSpacing: 2
                columnSpacing: 2

                property int firstDayIndex: {
                    var weekday = new Date(root.displayYear, root.displayMonth, 1).getDay()
                    return (weekday + 6) % 7
                }

                Repeater {
                    model: 42

                    Rectangle {
                        id: dayCell
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 20
                        radius: Math.min(width, height) / 2

                        property int cellIndex: index
                        property date cellDate: new Date(root.displayYear, root.displayMonth,
                                                        cellIndex - daysGrid.firstDayIndex + 1)
                        property string cellKey: root.dateKey(cellDate)
                        property bool isCurrentMonth: cellDate.getMonth() === root.displayMonth
                        property bool isToday: cellKey === root.dateKey(root.currentDate)
                        property bool isSelected: cellKey === root.dateKey(root.selectedDate)
                        property bool hasEvent: root.events[cellKey] !== undefined

                        color: isSelected ? root.currentTheme.accent
                                          : (dayMouse.containsMouse && isCurrentMonth ? root.currentTheme.panel : "transparent")
                        scale: dayMouse.pressed ? 0.96 : 1

                        Behavior on color { ColorAnimation { duration: 420 } }
                        Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.cellDate.getDate()
                            color: dayCell.isSelected ? root.currentTheme.bg
                                                       : (dayCell.isCurrentMonth ? root.currentTheme.text : root.currentTheme.muted)
                            opacity: dayCell.isCurrentMonth ? 1 : 0.55
                            font.pixelSize: root.isLarge ? 13 : 10
                            font.bold: dayCell.hasEvent || dayCell.isToday
                            Behavior on color { ColorAnimation { duration: 420 } }
                        }

                        Rectangle {
                            visible: dayCell.hasEvent
                            width: 4
                            height: 4
                            radius: 2
                            color: dayCell.isSelected ? root.currentTheme.bg : root.currentTheme.event
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.hoveredDateKey = dayCell.cellKey
                            onExited: root.hoveredDateKey = ""
                            onClicked: root.selectDate(dayCell.cellDate)
                            onDoubleClicked: root.openEventEditor(dayCell.cellDate)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.isLarge ? 34 : 0
                visible: root.isLarge
                color: root.currentTheme.panel
                radius: 8
                clip: true

                Behavior on color { ColorAnimation { duration: 420 } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: {
                        var key = root.hoveredDateKey || root.dateKey(root.selectedDate)
                        return root.events[key] || Qt.formatDate(new Date(key + "T00:00:00"), "ddd, MMM d") + "  |  No events"
                    }
                    color: root.currentTheme.accent
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 420 } }
                }
            }
        }

        CornerFrame {
            anchors.fill: parent
            anchors.margins: 1
            color: root.currentTheme.accent
            pulse: root.themePulse
            segmentLength: 9
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 8
        visible: root.settingsOpen
        color: root.currentTheme.bg
        border.color: Qt.darker(root.currentTheme.accent, 2.2)
        radius: 2

        Behavior on color { ColorAnimation { duration: 420 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Theme: " + root.currentTheme.name
                    color: root.currentTheme.text
                    font.pixelSize: 11
                    font.bold: true
                }

                DepthButton {
                    implicitWidth: 20
                    implicitHeight: 20
                    text: "x"
                    fontSize: 10
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: root.settingsOpen = false
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 5
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: root.themes

                    DepthButton {
                        id: themeSwatch
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        text: String(index + 1)
                        fontSize: 9
                        faceColor: modelData.panel
                        accentColor: modelData.accent
                        textColor: modelData.text
                        shadowColor: root.currentTheme.shadow
                        highlighted: root.themeIndex === index
                        onClicked: root.themeIndex = index
                    }
                }
            }

            Text {
                text: "Calendar app feed"
                color: root.currentTheme.muted
                font.pixelSize: 9
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                TextField {
                    id: calendarSourceInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    text: root.calendarSource
                    placeholderText: "iCalendar URL or .ics file"
                    color: root.currentTheme.text
                    placeholderTextColor: root.currentTheme.muted
                    font.pixelSize: 9
                    selectByMouse: true
                    onAccepted: {
                        root.calendarSource = text.trim()
                        root.refreshCalendarSource()
                    }
                    background: Rectangle {
                        color: root.currentTheme.shadow
                        border.color: root.currentTheme.panel
                        radius: 3
                    }
                }

                DepthButton {
                    implicitWidth: 42
                    implicitHeight: 30
                    text: "Sync"
                    fontSize: 9
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    textColor: root.currentTheme.text
                    shadowColor: root.currentTheme.shadow
                    onClicked: {
                        root.calendarSource = calendarSourceInput.text.trim()
                        root.refreshCalendarSource()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.feedStatus
                color: root.currentTheme.muted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Text {
                visible: !root.positionLocked
                enabled: !root.positionLocked
                text: "Widget location"
                color: root.currentTheme.muted
                font.pixelSize: 9
                font.bold: true
            }

            GridLayout {
                visible: !root.positionLocked
                enabled: !root.positionLocked
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 3
                columnSpacing: 4

                Repeater {
                    model: ["top-left", "top-right", "bottom-left", "bottom-right"]

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 21
                        text: modelData === "top-left" ? "TL"
                              : modelData === "top-right" ? "TR"
                              : modelData === "bottom-left" ? "BL" : "BR"
                        fontSize: 8
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        textColor: root.currentTheme.text
                        shadowColor: root.currentTheme.shadow
                        highlighted: root.anchorCorner === modelData
                        onClicked: if (!root.positionLocked) root.anchorCorner = modelData
                    }
                }
            }

            RowLayout {
                visible: !root.positionLocked
                enabled: !root.positionLocked
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: "X offset"
                    color: root.currentTheme.muted
                    font.pixelSize: 9
                }

                DepthButton {
                    implicitWidth: 22
                    implicitHeight: 20
                    text: "-"
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: if (!root.positionLocked) root.offsetX = Math.max(0, root.offsetX - 16)
                }

                Text {
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: root.offsetX
                    color: root.currentTheme.text
                    font.pixelSize: 9
                }

                DepthButton {
                    implicitWidth: 22
                    implicitHeight: 20
                    text: "+"
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: if (!root.positionLocked) root.offsetX = Math.min(600, root.offsetX + 16)
                }
            }

            RowLayout {
                visible: !root.positionLocked
                enabled: !root.positionLocked
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: "Y offset"
                    color: root.currentTheme.muted
                    font.pixelSize: 9
                }

                DepthButton {
                    implicitWidth: 22
                    implicitHeight: 20
                    text: "-"
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: if (!root.positionLocked) root.offsetY = Math.max(0, root.offsetY - 16)
                }

                Text {
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: root.offsetY
                    color: root.currentTheme.text
                    font.pixelSize: 9
                }

                DepthButton {
                    implicitWidth: 22
                    implicitHeight: 20
                    text: "+"
                    faceColor: root.currentTheme.panel
                    accentColor: root.currentTheme.accent
                    shadowColor: root.currentTheme.shadow
                    onClicked: if (!root.positionLocked) root.offsetY = Math.min(600, root.offsetY + 16)
                }
            }
        }

        CornerFrame {
            anchors.fill: parent
            anchors.margins: 1
            color: root.currentTheme.accent
            pulse: root.themePulse
            segmentLength: 12
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 10
        visible: root.editorOpen
        color: Qt.rgba(root.currentTheme.shadow.r, root.currentTheme.shadow.g,
                   root.currentTheme.shadow.b, 0.82)
        radius: 2

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 264
            radius: 2
            color: root.currentTheme.bg
            border.color: Qt.darker(root.currentTheme.accent, 2.2)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 5

                Text {
                    text: "Event reminder"
                    color: root.currentTheme.text
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: Qt.formatDate(root.selectedDate, "ddd, MMM d, yyyy")
                    color: root.currentTheme.muted
                    font.pixelSize: 11
                }

                Text {
                    text: "Event name"
                    color: root.currentTheme.muted
                    font.pixelSize: 10
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 5
                    color: root.currentTheme.shadow

                    TextInput {
                        id: eventTitleInput
                        focus: root.editorOpen
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.currentTheme.text
                        selectionColor: root.currentTheme.panel
                        font.pixelSize: 11
                        clip: true
                    }
                }

                Text {
                    text: "Time (24-hour)"
                    color: root.currentTheme.muted
                    font.pixelSize: 10
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 5
                    color: root.currentTheme.shadow

                    TextInput {
                        id: eventTimeInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.currentTheme.text
                        selectionColor: root.currentTheme.panel
                        font.pixelSize: 11
                        inputMethodHints: Qt.ImhTime
                        maximumLength: 5
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.editorError || "Notification 5 minutes before"
                    color: root.editorError ? root.currentTheme.event : root.currentTheme.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        text: "Cancel"
                        fontSize: 11
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        textColor: root.currentTheme.text
                        shadowColor: root.currentTheme.shadow
                        onClicked: root.editorOpen = false
                    }

                    DepthButton {
                        visible: root.selectedEventIsLocal
                        Layout.preferredWidth: root.selectedEventIsLocal ? 62 : 0
                        Layout.preferredHeight: 28
                        text: "Delete"
                        fontSize: 10
                        faceColor: root.currentTheme.event
                        accentColor: root.currentTheme.accent
                        textColor: root.currentTheme.bg
                        shadowColor: root.currentTheme.shadow
                        onClicked: root.deleteEvent()
                    }

                    DepthButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        text: "Save"
                        fontSize: 11
                        faceColor: root.currentTheme.panel
                        accentColor: root.currentTheme.accent
                        textColor: root.currentTheme.bg
                        shadowColor: root.currentTheme.shadow
                        highlighted: true
                        onClicked: root.saveEvent()
                    }
                }
            }

            CornerFrame {
                anchors.fill: parent
                anchors.margins: 1
                color: root.currentTheme.accent
                pulse: root.themePulse
                segmentLength: 12
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.checkReminders()
    }

    Process {
        id: calendarFeedProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: root.parseICalendar(text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.feedStatus = "Could not load calendar source"
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.calendarSource.trim().length > 0
        onTriggered: root.refreshCalendarSource()
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.refreshCurrentDate()
    }

    Process {
        command: ["notify-send", "--app-name=Calendar", "Calendar reminder", root.notificationMessage]
        running: root.notificationPending
        onExited: {
            root.notificationPending = false
            Qt.callLater(root.dispatchNotification)
        }
    }
}