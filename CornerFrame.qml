import QtQuick

Item {
    id: root

    property color color: "#8ed9d2"
    property color edgeColor: Qt.darker(root.color, 2.2)
    property int inset: 3
    property int segmentLength: 10
    property int thickness: 1
    property real pulse: 1

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.edgeColor
        border.width: 1
        radius: 2
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        border.color: Qt.darker(root.color, 3.4)
        border.width: 1
        radius: 1
    }

    Rectangle {
        width: root.segmentLength
        height: root.thickness
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: root.inset
        anchors.topMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }
    Rectangle {
        width: root.thickness
        height: root.segmentLength
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: root.inset
        anchors.topMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }

    Rectangle {
        width: root.segmentLength
        height: root.thickness
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: root.inset
        anchors.topMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }
    Rectangle {
        width: root.thickness
        height: root.segmentLength
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: root.inset
        anchors.topMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }

    Rectangle {
        width: root.segmentLength
        height: root.thickness
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.inset
        anchors.bottomMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }
    Rectangle {
        width: root.thickness
        height: root.segmentLength
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.inset
        anchors.bottomMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }

    Rectangle {
        width: root.segmentLength
        height: root.thickness
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.inset
        anchors.bottomMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }
    Rectangle {
        width: root.thickness
        height: root.segmentLength
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.inset
        anchors.bottomMargin: root.inset
        color: root.color
        opacity: 0.35 + root.pulse * 0.5
    }
}