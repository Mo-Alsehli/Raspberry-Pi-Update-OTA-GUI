import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "components"

Window {
    id: root
    // width: maximumWidth
    // height: maximumHeight
    visibility: "Maximized"
    visible: true
    title: qsTr("OTA Update Manager")

    // Custom Properties
    property string updateState: "idle"

    Connections {
        target: otaController

        function onUpdateCheckStarted() {
            updateState = "checking"
        }

        function onUpdateCheckDone(updateRequest) {
            console.log("update Req " + updateRequest)
            switch(updateRequest){
            case 0:
                updateState = "updateAvailable"
                break
            case 1:
                updateState = "upToDate"
                break
            default:
                updateState = "requestRefused"
            }
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
        id: mainScrollView
        anchors.fill: parent
        anchors.margins: 50
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: content
            width: mainScrollView.availableWidth
            spacing: 30

            // HEADER
            Rectangle {
                id: header
                width: parent.width
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
                        Layout.alignment: Qt.AlignRight
                        anchors.right: parent.right

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            OnlineStatusIndicator {
                                connected: otaController.serverConnected
                            }

                            Text {
                                text: otaController.serverConnected
                                          ? "Connected to QNX Server"
                                          : "Server Disconnected"
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
            Row {
                id: mainWindow
                width: parent.width
                spacing: 20

                Column {
                    id: leftSection
                    width: parent.width * 0.70
                    spacing: 25

                    Rectangle {
                        id: updateArea
                        width: parent.width
                        height: updateLoader.item ? updateLoader.item.implicitHeight : 300
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

                        CardShadow {
                            target: updateArea
                            anchors.fill: updateArea
                        }
                    }

                    Rectangle {
                        id: systemStatus
                        color: "#fefae0"
                        radius: 15
                        border.width: 1
                        border.color: "#e2e8f0"
                        width: parent.width
                        height: statusContentColumn.implicitHeight + 40

                        Column {
                            id: statusContentColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 20
                            anchors.leftMargin: 30
                            spacing: 40

                            Rectangle {
                                id: statusHeader
                                width: parent.width
                                height: 30
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
                                spacing: 20
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
                                spacing: 20
                                StatusTile {
                                    iconSource: "../assets/shield.png"
                                    title: qsTr("CommonAPI")
                                    subtitle: otaController.serverConnected ?
                                                qsTr("Connected") :
                                                qsTr("Disconnected")
                                    statusText: qsTr("v3.2.4")
                                }
                                StatusTile {
                                    iconSource: "../assets/blackberry.png"
                                    title: qsTr("Client")
                                    subtitle: qsTr("Running")
                                    statusText: qsTr("RPi4")
                                }
                            }
                        }

                        CardShadow {
                            target: systemStatus
                            anchors.fill: systemStatus
                        }
                    }
                }

                Column {
                    id: rightSection
                    width: parent.width - leftSection.width - 20
                    spacing: 30

                    Rectangle {
                        id: systemInfo
                        width: parent.width
                        height: infoColumn.implicitHeight + 60
                        color: "#fefae0"
                        radius: 15
                        border.width: 1
                        border.color: "#e2e8f0"

                        Column {
                            id: infoColumn
                            width: parent.width - 60
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 30
                            spacing: 20

                            Rectangle {
                                id: infoHeader
                                width: parent.width
                                height: 30
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
                                width: parent.width
                                height: 1
                                color: "#adb5bd"
                            }

                            Column {
                                id: devices
                                spacing: 10
                                width: parent.width

                                MetricRow {
                                    source: "../assets/cpu.png"
                                    text: qsTr("CPU")
                                    deviceData: otaController.cpuPercent + "%"
                                }

                                MetricRow {
                                    source: "../assets/ram.png"
                                    text: qsTr("Memory")
                                    deviceData: otaController.memoryText
                                }

                                MetricRow {
                                    source: "../assets/memory-card.png"
                                    text: qsTr("Storage")
                                    deviceData: otaController.storageText
                                }

                                MetricRow {
                                    source: "../assets/temp.png"
                                    text: qsTr("Tempreture")
                                    deviceData: otaController.temperatureC + "°C"
                                }
                            }

                            Rectangle {
                                id: solidLine2
                                width: parent.width
                                height: 1
                                color: "#adb5bd"
                            }

                            Column {
                                id: rpiInfo
                                spacing: 10
                                width: parent.width

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
                        color: "#fefae0"
                        radius: 15
                        border.width: 1
                        border.color: "#e2e8f0"
                        width: parent.width
                        height: 400

                        ScrollView {
                            id: logsScroll
                            anchors.fill: parent
                            anchors.margins: 20
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded

                            ColumnLayout {
                                id: logsColumn
                                width: logsScroll.availableWidth
                                spacing: 10

                                MetricRow {
                                    id: logsheader
                                    Layout.fillWidth: true
                                    source: "../assets/log.png"
                                    text: "Activity Logs"
                                    deviceData: ""
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Dashboard reset"
                                    myDate: "04:03:16 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Update file received"
                                    myDate: "04:04:10 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "CRC check passed"
                                    myDate: "04:05:30 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Installation started"
                                    myDate: "04:06:15 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Verifying integrity"
                                    myDate: "04:07:22 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Update completed"
                                    myDate: "04:08:45 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "System reboot required"
                                    myDate: "04:09:10 PM"
                                }

                                LogEntry {
                                    Layout.fillWidth: true
                                    source: "../assets/info.png"
                                    text: "Backup created"
                                    myDate: "04:10:00 PM"
                                }
                            }
                        }
                    }
                }
            }

            // Bottom spacer to ensure all content is visible when scrolling
            Item {
                width: parent.width
                height: 50
            }
        }
    }
}
