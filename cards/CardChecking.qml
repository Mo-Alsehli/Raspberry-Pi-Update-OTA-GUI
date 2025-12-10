import QtQuick

Rectangle {
    id: cardChecking
    width: parent.width
    implicitHeight: contentColumn.implicitHeight + 60
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"
    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: 35
        anchors.margins: 30

        Image {
            id: refreshIcon
            source: "../assets/refresh.png"
            opacity: 0.5
            width: 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter

            transform: Rotation {
                id: rotation
                origin.x: refreshIcon.width / 2
                origin.y: refreshIcon.height / 2
                NumberAnimation on angle {
                    from: 0
                    to: 360
                    duration: 1500
                    running: true
                    loops: Animation.Infinite
                }
            }



        }

        Text {
            text: qsTr("Checking For Updates")
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Quering QNX Server Via CommonAPI...")
            font.pixelSize: 20
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#64748b"
        }

    }

    Timer {
        id: autoComplete
        interval: 2000
        running: true
        repeat: false

        onTriggered: {
            cardChecking.checkForUpdate()
        }
    }


    signal checkForUpdate()
}
