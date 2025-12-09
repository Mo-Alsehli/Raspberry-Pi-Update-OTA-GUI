import QtQuick

Rectangle {
    id: root
    property alias iconSource: statusImg.source
    property string title
    property string subtitle
    property string statusText
    property color statusColor: "#e2e8f0"

    color: "#e5e5e5"
    radius: 10
    border.width: 1
    border.color: "#e2e8f0"
    width: parent.width / 2
    height: 130
    anchors.verticalCenter: parent.verticalCenter


    Column {
        width: parent.width / 3
        height: parent.height
        spacing: 5
        anchors.margins: 25
        anchors.fill: parent
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        Row {
            spacing: 7
            anchors.left: parent.left
            Image {
                id: statusImg
                //source: iconSource
                width: 27
                height: 27
            }

            Text {
                text: title
                font.pixelSize: 18
                color: "#6c757d"
            }
        }

        Row {
            spacing: 7
            anchors.left: parent.left
            OnlineStatusIndicator {
                color: "#22c553"
            }

            Text {
                text: subtitle
                font.pixelSize: 18

            }
        }

        Text {
            text: statusText
            font.pixelSize: 18
            color: "#6c757d"
        }


    }

}
