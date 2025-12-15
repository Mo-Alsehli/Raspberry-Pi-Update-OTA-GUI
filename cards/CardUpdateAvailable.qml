import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Rectangle {
    id: updateAvailable
    width: parent.width
    implicitHeight: contentColumn.implicitHeight + 60
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"

    property real updateSize: Math.round(otaController.totalSize / (1024 * 1024))
    property string updateVersion: "1.0.0"
    property string updateDate: "9 Dec, 2025"



    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: 20
        anchors.margins: 30

        Image {
            source: "../assets/download-update.png"
            opacity: 0.5
            width: 50
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Update Available")
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("New Linux image found on server")
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#64748b"
        }

        // -------------------------------------------------------
        // UPDATE INFO BOX
        // -------------------------------------------------------
        Rectangle {
            color: "#e5e5e5"
            radius: 10
            border.width: 1
            border.color: "#e2e8f0"
            width: parent.width * 0.85
            height: 180
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: infoColumn
                anchors.fill: parent
                anchors.margins: 25
                spacing: 18


                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: "Size:"
                        font.pixelSize: 20
                        anchors.left: parent.left
                    }
                    Text {
                        text: updateAvailable.updateSize + " MB"
                        font.pixelSize: 18
                        color: "#1e293b"
                        anchors.right: parent.right
                    }
                }


                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: "Version:"
                        font.pixelSize: 20
                        anchors.left: parent.left
                    }
                    Text {
                        text: updateAvailable.updateVersion
                        font.pixelSize: 18
                        color: "#1e293b"
                        anchors.right: parent.right
                    }
                }

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: "Date:"
                        font.pixelSize: 20
                        anchors.left: parent.left
                    }
                    Text {
                        text: updateAvailable.updateDate
                        font.pixelSize: 18
                        color: "#1e293b"
                        anchors.right: parent.right
                    }
                }
            }
        }

        PrimaryButton {
            id: updateBtn
            width: parent.width * 0.85
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Download Update"
            iconSource: "../assets/download.png"
            color: updateBtn.hovered ? "#a3b18a" :"#588157"

            onClicked: updateAvailable.downloadUpdate()
        }
    }
    // Signal for requesting download
    signal downloadUpdate()
}
