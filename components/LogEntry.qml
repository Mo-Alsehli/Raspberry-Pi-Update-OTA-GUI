import QtQuick


Rectangle {
    width: parent.width
    height: 85
    radius: 10
    color: "#e5e5e5"
    border.width: 1
    border.color: "#e2e8f0"

    property alias source: logImg.source
    property alias text: logText.text
    property alias myDate: logDate.text

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15
        Row {
            id: mylog
            width: parent.width
            height: parent.height / 2
            Image {
                id: logImg
                width: 25
                height: 25
                anchors.left: parent.left
            }

            Text {
                id: logText
                anchors.left: logImg.right
                font.pixelSize: 20
                anchors.leftMargin: 10
            }
        }

        Row {
            width: parent.width
            anchors.top: mylog.bottom
            Text {
                id:  logDate
                font.pixelSize: 18
                color: "#1e293b"
            }
        }
    }

}
