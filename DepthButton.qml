import QtQuick

Item {
    id: root

    property string text: ""
    property color faceColor: "#30464d"
    property color accentColor: "#8ed9d2"
    property color textColor: "#e5f3f2"
    property color shadowColor: "#071014"
    property bool highlighted: false
    property int fontSize: 10
    signal clicked()

    implicitWidth: 24
    implicitHeight: 22
    y: pointer.pressed ? 2 : 0
    scale: pointer.pressed ? 0.97 : (pointer.containsMouse ? 1.03 : 1)

    Behavior on y { NumberAnimation { duration: 75; easing.type: Easing.OutCubic } }
    Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.36 } }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: 3
        color: root.shadowColor
    }

    Rectangle {
        id: face
        anchors.fill: parent
        anchors.bottomMargin: pointer.pressed ? 0 : 3
        radius: 3
        border.width: 1
        border.color: pointer.pressed ? root.accentColor : Qt.darker(root.faceColor, 1.18)

        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.highlighted ? Qt.lighter(root.accentColor, 1.12)
                                        : Qt.lighter(root.faceColor, 1.28)
            }
            GradientStop {
                position: 0.42
                color: root.highlighted ? root.accentColor : root.faceColor
            }
            GradientStop {
                position: 1
                color: root.highlighted ? Qt.darker(root.accentColor, 1.18)
                                        : Qt.darker(root.faceColor, 1.28)
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 2
            height: 1
            radius: 1
            color: Qt.lighter(root.faceColor, 1.7)
            opacity: pointer.pressed ? 0.35 : 0.72
        }
    }

    Text {
        anchors.fill: parent
        y: pointer.pressed ? 1 : -1
        text: root.text
        color: root.textColor
        font.pixelSize: root.fontSize
        font.bold: root.highlighted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}