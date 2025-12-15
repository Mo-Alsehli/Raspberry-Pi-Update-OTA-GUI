import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "components"

Window {
    id: root
    width: maximumWidth
    height: maximumHeight
    visible: true
    title: qsTr("OTA Update Manager")

    // Custom Properties
    property string updateState: "idle"

    Connections {
        target: otaController

        function onUpdateCheckDone(available) {
            updateState = available ? "updateAvailable" : "upToDate"
        }

        function onProgressChanged(percent) {

            if(updateState != "downloadUpdate"){
                updateState = "downloadUpdate"
            }
        }

        function onDownloadFinished() {
            updateState = "downloadFinished"
        }

        function onDownloadRejected() {
            updateState = "requestRefused"
        }

        function onErrorOccurred(message) {
            console.log("OTA error: ", message)
            updateState = "requestRefused"
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 1.0; color: "#22223b" }
            GradientStop { position: 0.0; color: "#f6fff8" }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 50
        width: parent.width



        ColumnLayout {
            id: content
            width: parent.width
            spacing: 30

            // HEADER
            Rectangle {
                id: header
                Layout.fillWidth: true
                height: 120
                radius: 5
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Left side
                    ColumnLayout {
                        spacing: 5
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "OTA Update Manager"
                            font.pixelSize: 32
                            font.bold: true
                            color: "#1e293b"
                        }

                        Text {
                            text: "Raspberry Pi 4 Client - SOME/IP Protocol"
                            font.pixelSize: 16
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true } // Spacer

                    // Right side: Status badge
                    Rectangle {
                        id: statusBadge
                        height: 45
                        width: 250
                        radius: 14
                        color: "white"
                        border.width: 1
                        border.color: "#e2e8f0"
                        anchors.right: parent.right

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            OnlineStatusIndicator {
                                color: "#22c553"
                            }

                            Text {
                                text: "Connected to QNX Server"
                                font.pixelSize: 18
                                color: "#1e293b"
                            }
                        }
                    }

                    CardShadow {
                        target: statusBadge
                        anchors.fill: statusBadge
                    }
                }
            }

            // MAIN WINDOW
            Rectangle {
                id: mainWindow
                Layout.fillWidth: true
                Layout.preferredHeight: root.height - header.height  // Set a specific height
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Column {
                        id: leftSection
                        width: parent.width * 0.70
                        height: parent.height
                        spacing: 25

                        Rectangle {
                            id: updateArea
                            width: parent.width
                            height: updateLoader.item ? updateLoader.item.implicitHeight: implicitHeight
                            radius: 15
                            border.width: 1
                            border.color: "#e2e8f0"
                            color: "transparent"

                            Loader {
                                id: updateLoader
                                anchors.fill: parent



                                source: {
                                    switch(updateState){
                                    case "idle": return "cards/CardIdle.qml"
                                    case "checking": return "cards/CardChecking.qml"
                                    case "upToDate": return "cards/CardUpToDate.qml"
                                    case "updateAvailable": return "cards/CardUpdateAvailable.qml"
                                    case "requestRefused": return "cards/CardRequestRefused.qml"
                                    case "downloadUpdate": return "cards/CardDownloading.qml"
                                    case "downloadFinished": return "cards/CardDownloadFinished.qml"
                                    default: return "cards/CardIdle.qml"
                                    }
                                }

                                onLoaded: {
                                    if(item && item.requestUpdate) {
                                        item.requestUpdate.connect(() => {
                                            updateState = "checking"
                                            otaController.checkForUpdate();
                                        })
                                    }

                                    if(item && item.returnRequested) {
                                        item.returnRequested.connect(() => updateState = "idle" )
                                    }

                                    if(item && item.checkForUpdate){
                                        item.checkForUpdate.connect(() => {
                                            updateState = "updateAvailable"
                                        })
                                    }

                                    if(item && item.downloadUpdate){
                                            item.downloadUpdate.connect(() => {
                                                updateState = "downloadUpdate"
                                                otaController.startDownload()
                                            })
                                        }


                            }
                        }
                    }

                        CardShadow {
                            target: updateArea
                            anchors.fill: updateArea
                        }


                        Rectangle {
                            id: systemStatus
                            anchors.top: updateArea.bottom
                            color: "#fefae0"
                            radius: 15
                            border.width: 1
                            border.color: "#e2e8f0"
                            width: parent.width
                            height: parent.height / 2
                            anchors.topMargin: 30

                            Column {
                                //width: parent.width
                                //height: parent.height
                                anchors.fill: parent
                                anchors.margins: 20
                                anchors.leftMargin: 30
                                spacing: 40
                                anchors.horizontalCenter: parent.horizontalCenter
                                Rectangle {
                                    id: statusHeader
                                    width: parent.width
                                    height: 30
                                    anchors.top: parent.top
                                    color: "transparent"

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "System Status"
                                        font.bold: true
                                        color: "#1e293b"
                                        font.pixelSize: 18
                                    }
                                }

                                Row {
                                    id: firstStatusRow
                                    width: parent.width - 30
                                    anchors.margins: 10
                                    anchors.topMargin: 30
                                    spacing: 20
                                    anchors.top: statusHeader.bottom


                                    StatusTile {
                                        iconSource: "../assets/server.png"
                                        title: qsTr("Server")
                                        subtitle: qsTr("QNX VM")
                                        statusText: qsTr("Ubuntu Host")
                                    }

                                    StatusTile {
                                        iconSource: "../assets/ethernet.png"
                                        title: qsTr("Protocol")
                                        subtitle: qsTr("SOME/IP")
                                        statusText: qsTr("IDLE")
                                    }
                                }

                                Row {
                                    width: parent.width - 30
                                    anchors.margins: 10
                                    spacing: 20
                                    anchors.top: firstStatusRow.bottom
                                    anchors.topMargin: 20

                                    StatusTile {
                                        iconSource: "../assets/shield.png"
                                        title: qsTr("CommonAPI")
                                        subtitle: qsTr("Connected")
                                        statusText: qsTr("v3.2.0")
                                    }

                                    StatusTile {
                                        iconSource: "../assets/blackberry.png"
                                        title: qsTr("Client")
                                        subtitle: qsTr("Running")
                                        statusText: qsTr("RPi4")
                                    }
                                }
                            }
                        }

                        CardShadow {
                            target: systemStatus
                            anchors.fill: systemStatus

                        }


                    }

                    Column {
                        id: rightSection
                        width: (parent.width - leftSection.width) - 30
                        height: parent.height
                        anchors.right: parent.right

                        Rectangle {
                            id: systemInfo
                            width: parent.width
                            height: parent.height * 0.60
                            color: "#fefae0"
                            radius: 15
                            border.width: 1
                            border.color: "#e2e8f0"
                            anchors.bottomMargin: 13

                            Column {
                                width: parent.width
                                height: parent.height
                                anchors.fill: parent
                                anchors.margins: 30


                                Rectangle {
                                    id: infoHeader
                                    width: parent.width
                                    height: 30
                                    anchors.top: parent.top
                                    color: "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "System Information"
                                        font.bold: true
                                        color: "#1e293b"
                                        font.pixelSize: 18
                                    }
                                }

                                Rectangle {
                                    id: solidLine
                                    anchors.top: infoHeader.bottom
                                    width: parent.width
                                    height: 1
                                    color: "#adb5bd"
                                    anchors.topMargin: 20
                                    anchors.bottomMargin: 20
                                }

                                Column {
                                    id: devices
                                    spacing: 10
                                    width: parent.width
                                    height: parent.height * 0.4
                                    anchors.top: solidLine.bottom
                                    anchors.topMargin: 20

                                    MetricRow {
                                        source: "../assets/cpu.png"
                                        text: qsTr("CPU")
                                        deviceData: qsTr("42%")
                                    }

                                    MetricRow {
                                        source: "../assets/ram.png"
                                        text: qsTr("Memory")
                                        deviceData: qsTr("1/2 GB")
                                    }

                                    MetricRow {
                                        source: "../assets/memory-card.png"
                                        text: qsTr("Storage")
                                        deviceData: qsTr("8.3/32 GB")
                                    }

                                    MetricRow {
                                        source: "../assets/temp.png"
                                        text: qsTr("Tempreture")
                                        deviceData: qsTr("60°C")
                                    }
                                }

                                Rectangle {
                                    id: solidLine2
                                    anchors.top: devices.bottom
                                    width: parent.width
                                    height: 1
                                    color: "#adb5bd"
                                    anchors.topMargin: 30
                                    anchors.bottomMargin: 20
                                }

                                Column {
                                    id: rpiInfo
                                    spacing: 10
                                    width: parent.width
                                    //height: parent.height * 0.4
                                    anchors.top: solidLine2.bottom
                                    anchors.topMargin: 20

                                    MetricRow {
                                        source: "../assets/blackberry.png"
                                        text: qsTr("Device")
                                        deviceData: qsTr("Raspberry Pi 4")
                                    }

                                    MetricRow {
                                        source: "../assets/blackberry.png"
                                        text: qsTr("Architecture")
                                        deviceData: qsTr("ARM64")
                                    }

                                    MetricRow {
                                        source: "../assets/blackberry.png"
                                        text: qsTr("Uptime")
                                        deviceData: qsTr("12d 4h 23m")
                                    }
                                }
                            }

                        }


                        Rectangle {
                            id: logs
                            anchors.top: systemInfo.bottom
                            color: "#fefae0"
                            radius: 15
                            border.width: 1
                            border.color: "#e2e8f0"
                            width: parent.width
                            height: parent.height * 0.35
                            anchors.topMargin: 30
                            anchors.bottomMargin: 10

                            Column {
                                width: parent.width
                                height: parent.height
                                anchors.fill: parent
                                anchors.margins: 20




                                ScrollView {
                                    id: logsScroll
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    anchors.fill: parent

                                    ColumnLayout {
                                        id: logsColumn
                                        width: parent.width
                                        spacing: 10

                                        MetricRow {
                                            id: logsheader
                                            source: "../assets/log.png"
                                            text: "Activity Logs"
                                            deviceData: ""
                                        }

                                        LogEntry {
                                            source: "../assets/info.png"
                                            text: "Dashboard reset"
                                            myDate: "04:03:16 PM"
                                        }

                                        LogEntry {
                                            source: "../assets/info.png"
                                            text: "Update file received"
                                            myDate: "04:04:10 PM"
                                        }

                                        LogEntry {
                                            source: "../assets/info.png"
                                            text: "CRC check passed"
                                            myDate: "04:05:30 PM"
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}
