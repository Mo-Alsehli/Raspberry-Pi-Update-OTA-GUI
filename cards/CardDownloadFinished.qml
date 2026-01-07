import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: finishedCard
    width: parent.width
    implicitHeight: contentColumn.implicitHeight + 60
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"

    // Signals sent to Main.qml
    signal applyUpdate()
    signal returnRequested()

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 30
        spacing: 25

        // Success icon
        Image {
            source: "../assets/checkmark.png"
            width: 70
            height: 70
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Update Received Successfully"
            font.pixelSize: 22
            font.bold: true
            color: "#1e293b"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Ready to apply new system image"
            font.pixelSize: 16
            color: "#64748b"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Main button: Reboot & Apply Update
        PrimaryButton {
            width: parent.width * 0.85
            anchors.horizontalCenter: parent.horizontalCenter
            iconSource: "../assets/power.png"
            text: "Reboot & Apply Update"

            btnColor: down ? "#aa2e00" :
                     (hovered ? "#ff6420" : "#ff4500")

            onClicked: otaController.applyUpdate()
        }

        // Secondary button: Return to Dashboard
        Rectangle {
            width: parent.width * 0.85
            height: 45
            radius: 15
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#dfe3ea"

            MouseArea {
                anchors.fill: parent
                onClicked: finishedCard.returnRequested()
            }

            Text {
                text: "Return to Dashboard"
                anchors.centerIn: parent
                font.pixelSize: 16
                color: "#1e293b"
            }
        }
    }
}
