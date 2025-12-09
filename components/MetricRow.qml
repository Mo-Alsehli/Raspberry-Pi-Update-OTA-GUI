import QtQuick

Rectangle {
    width: parent.width
    height: 40
    color: "transparent"

    property alias source: deviceImg.source
    property alias text: deviceName.text
    property string deviceData

    Row {
        anchors.fill: parent
        width: parent.width
        height: parent.height

        Image {
            id: deviceImg
            width: 25
            height: 25
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: deviceName
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: deviceImg.right
            anchors.leftMargin: 12
        }

        Text {
            text: deviceData
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.leftMargin: 12
        }
    }
}
