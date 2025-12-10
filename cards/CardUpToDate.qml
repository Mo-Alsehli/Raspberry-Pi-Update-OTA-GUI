import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"


Rectangle {
    id: upToDate
    width: parent.width
    implicitHeight: contentColumn.implicitHeight + 60
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"
    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: 17
        anchors.margins: 30

        Image {
            source: "../assets/checkmark.png"
            opacity: 0.5
            width: 60
            height: 60
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("System Up To Date")
            font.pixelSize: 20
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("No new updates available")
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#64748b"
        }

        PrimaryButton {
            id: backBtn
            width: parent.width * 0.85
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Back"
            color: backBtn.hovered ? "#adb5bd" : "#6c757d"
            iconSource: ""
            onClicked: upToDate.returnRequested()
        }
    }

    signal returnRequested()
}
