import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"


Rectangle {
    id: cardDownloading
    width: parent.width
    implicitHeight: mainColumn.implicitHeight + 60
    color: "#fefae0"
    radius: 15
    border.width: 1
    border.color: "#e2e8f0"

    property int progressPercent: otaController.progress
    property int downloadedMB: Math.round((progressPercent / 100) * totalMB)
    property int totalMB: Math.round(otaController.totalSize / (1024 * 1024))
    property real speedMB: otaController.speedMBps.toFixed(1)
    property int chunksReceived: otaController.chunksReceived
    property int totalChunks: otaController.totalChunks

    property int uiSegments: 20
    property int currentSegment: {
        if (totalChunks <= 0)
            return 0;

        return Math.min(
            uiSegments - 1,
            Math.floor((chunksReceived * uiSegments) / totalChunks)
        );
    }





    Column {
        id: mainColumn
        anchors.fill: parent
        spacing: 30
        anchors.margins: 30

        // First Card
        Rectangle {
            width: parent.width
            radius: 10
            color: "#ffffff"
            border.width: 1
            border.color: "#e2e8f0"
            implicitHeight: headerColumn.implicitHeight + 40
            Column {
                id: headerColumn
                anchors.margins: 20
                anchors.fill: parent
                spacing: 20

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
                    text: qsTr("Downloading Update")
                    font.pixelSize: 18
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: qsTr("Receiving image chunks via SOME/IP...")
                    font.pixelSize: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#64748b"
                }
            }

        }


        Rectangle {
            radius: 10
            color: "#ffffff"
            border.width: 1
            border.color: "#e2e8f0"
            width: parent.width
            implicitHeight: progressColumn.implicitHeight + 40

            Column {
                id: progressColumn
                anchors.fill: parent
                anchors.margins: 25
                spacing: 20

                Row {
                    spacing: 10
                    Image {
                        source: "../assets/download.png"
                        width: 20
                        height: 20
                    }

                    Text {
                        text: "Transfer Progress"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#1e293b"
                    }
                }

                Row {
                    spacing: 10
                    width: parent.width

                    Text {
                        text: "Downloading"
                        font.pixelSize: 16
                        color: "#1e293b"
                    }

                    Item { Layout.fillWidth: true}

                    Text {
                        text: progressPercent + "%"
                        font.pixelSize: 16
                        color: "#1e293b"
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 10
                    radius: 5
                    color: "#d0d5dd"

                    Rectangle {
                        width: parent.width * (progressPercent / 100.0)
                        height: parent.height
                        radius: 5
                        color: "#007bff"
                    }
                }

                Row {
                    width: parent.width
                    spacing: 20

                    // Downloaded
                    Rectangle {
                        width: (parent.width - 40) / 3
                        height: 70
                        radius: 12
                        color: "#f0f2f5"

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "Downloaded"
                                color: "#1e293b"
                            }

                            Text {
                                text: downloadedMB + " MB"
                                font.bold: true
                            }
                        }
                    }

                    // Speed
                    Rectangle {
                        width: (parent.width - 40) / 3
                        height: 70
                        radius: 12
                        color: "#f0f2f5"

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "Speed"
                                color: "#1e293b"
                            }

                            Text {
                                text: speedMB + " MB/s"
                                font.bold: true
                            }
                        }
                    }

                    // Total Size
                    Rectangle {
                        width: (parent.width - 40) / 3
                        height: 70
                        radius: 12
                        color: "#f0f2f5"

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "Total Size"
                                color: "#1e293b"
                            }

                            Text {
                                text: totalMB + " MB"
                                font.bold: true
                            }
                        }
                    }

                }
                // Chunk Progress

                Text {
                    text: "Chunks Received: " + chunksReceived + "/" + totalChunks
                    font.pixelSize: 15
                    color: "#1e293b"
                }


                Row {
                    id: chunkRow
                    spacing: 10
                    width: parent.width

                    // Colors
                        property color receivedColor: "#007BFF"
                        property color currentColor:  "#7DBBFF"
                        property color pendingColor:  "#DCE3ED"

                    Repeater {
                        model: uiSegments

                        Rectangle {
                            width: (chunkRow.width - (uiSegments - 1) * chunkRow.spacing) / uiSegments
                            height: 16
                            radius: 4
                            color: {
                                if (index < currentSegment ||
                                    (chunksReceived >= totalChunks && index === currentSegment)) {
                                    return chunkRow.receivedColor;
                                } else if (index === currentSegment) {
                                    return chunkRow.currentColor;
                                } else {
                                    return chunkRow.pendingColor;
                                }
                            }

                        }
                    }
                }




            }
        }

    }

}
