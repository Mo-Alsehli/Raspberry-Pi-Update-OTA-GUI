import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"


Rectangle {
    id: idleCard
    width: parent.width
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"
    implicitHeight: contentColumn.implicitHeight + 60

    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: 20
        anchors.margins: 30

        Image {
            source: "../assets/download.png"
            opacity: 0.5
            width: 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Ready")
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Click below to check for system updates")
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#64748b"
        }

        PrimaryButton {
            id: checkBtn
            width: parent.width * 0.85
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Check For Updates"
            iconSource: "../assets/refresh.png"
            btnColor: checkBtn.down ? "#012b3a" : (checkBtn.hovered ? "#034b6a" : "#023047")
            onClicked: idleCard.requestUpdate()
        }
    }

    signal requestUpdate()
}
