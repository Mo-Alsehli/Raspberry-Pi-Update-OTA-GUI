import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: parent ? parent.width : 200
    anchors.horizontalCenter: parent.horizontalCenter
    height: 45
    radius: 15

    property color btnColor

    color: btnColor
    property alias text: buttonText.text
    property url iconSource: ""

    signal clicked()

    property bool hovered: false
    property bool down: false


    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.down = true
        onReleased: root.down = false

        onClicked: root.clicked()
    }

    Row {
        spacing: 10
        anchors.centerIn: parent

        Image {
            source: root.iconSource
            visible: root.iconSource != ""
            width: 20
            height: 20
        }

        Text {
            id: buttonText
            color: "white"
            font.bold: true
        }
    }
}
