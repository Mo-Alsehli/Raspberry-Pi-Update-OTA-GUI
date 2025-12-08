import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Window {
    id: root
    width: maximumWidth
    height: maximumHeight
    visible: true
    title: qsTr("OTA Update Manager")

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

        component OnlineCircle: Rectangle {
            id: mycircle
            property alias color:  mycircle.color
            width: 10
            height: 10
            radius: 5
            anchors.verticalCenter: parent.verticalCenter
        }

        component MyShadow: MultiEffect {
            id: myshadow
            shadowBlur: 1.0
            shadowEnabled: true
            shadowColor: "#22000000"
            shadowVerticalOffset: 10
            shadowHorizontalOffset: 7
        }

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

                            OnlineCircle {
                                color: "#22c553"
                            }

                            Text {
                                text: "Connected to QNX Server"
                                font.pixelSize: 18
                                color: "#1e293b"
                            }
                        }
                    }

                    MyShadow {
                        source: statusBadge
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
                            height: (parent.height / 3)
                            color: "#fefae0"
                            radius: 15
                            border.width: 1
                            border.color: "#e2e8f0"
                            anchors.bottomMargin: 13
                            Column {
                                anchors.fill: parent
                                spacing: 20
                                anchors.margins: 30

                                Image {
                                    source: "assets/download.png"
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


                                Button {
                                    width: parent.width * 0.85
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 45

                                    background: Rectangle {
                                        color: "#023047"
                                        radius: 15
                                        border.width: 0
                                    }

                                    Row {
                                        spacing: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Image {
                                            source: "assets/refresh.png"
                                            width: 20
                                            height: 20
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            id: checkUpdateText
                                            text: qsTr("Check for Updates")
                                            color: "white"
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    onClicked: {
                                        // Your button action here
                                    }
                                }
                            }
                        }

                        MyShadow {
                            source: updateArea
                            anchors.fill: updateArea
                        }

                        component StatusRect: Rectangle {
                            id: statusRect
                            property alias source: img.source
                            property alias header: statusName.text
                            property alias machine: machine.text
                            property alias host: host.text

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
                                        id: img
                                        width: 27
                                        height: 27
                                    }

                                    Text {
                                        id: statusName
                                        font.pixelSize: 18
                                        color: "#6c757d"
                                    }
                                }

                                Row {
                                    spacing: 7
                                    anchors.left: parent.left
                                    OnlineCircle {
                                        color: "#22c553"
                                    }

                                    Text {
                                        id: machine
                                        font.pixelSize: 18

                                    }
                                }

                                Text {
                                    id: host
                                    font.pixelSize: 18
                                    color: "#6c757d"
                                }


                            }

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
                                width: parent.width
                                height: parent.height
                                anchors.fill: parent
                                anchors.margins: 30
                                spacing: 20
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
                                    width: parent.width
                                    anchors.margins: 25
                                    spacing: 20
                                    anchors.top: statusHeader.bottom

                                    StatusRect {
                                        source: "assets/server.png"
                                        header: qsTr("Server")
                                        machine: qsTr("QNX VM")
                                        host: qsTr("Ubuntu Host")
                                    }

                                    StatusRect {
                                        source: "assets/ethernet.png"
                                        header: qsTr("Protocol")
                                        machine: qsTr("SOME/IP")
                                        host: qsTr("IDLE")
                                    }
                                }

                                Row {
                                    width: parent.width
                                    anchors.margins: 25
                                    spacing: 20
                                    anchors.top: firstStatusRow.bottom

                                    StatusRect {
                                        source: "assets/shield.png"
                                        header: qsTr("CommonAPI")
                                        machine: qsTr("Connected")
                                        host: qsTr("v3.2.0")
                                    }

                                    StatusRect {
                                        source: "assets/blackberry.png"
                                        header: qsTr("Client")
                                        machine: qsTr("Running")
                                        host: qsTr("RPi4")
                                    }
                                }
                            }
                        }

                        MyShadow {
                            source: systemStatus
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
                                component DeviceText: Rectangle {
                                    width: parent.width
                                    height: 40
                                    color: "transparent"

                                    property alias source: deviceImg.source
                                    property alias text: deviceName.text
                                    property alias deviceData: deviceData.text

                                    Row {
                                        anchors.fill: parent
                                        width: parent.width
                                        height: parent.height

                                        Image {
                                            id: deviceImg
                                            width: 25
                                            height: 25
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            id: deviceName
                                            font.pixelSize: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: deviceImg.right
                                            anchors.leftMargin: 12
                                        }

                                        Text {
                                            id: deviceData
                                            font.pixelSize: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            anchors.leftMargin: 12
                                        }
                                    }
                                }

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

                                    DeviceText {
                                        source: "assets/cpu.png"
                                        text: qsTr("CPU")
                                        deviceData: qsTr("42%")
                                    }

                                    DeviceText {
                                        source: "assets/ram.png"
                                        text: qsTr("Memory")
                                        deviceData: qsTr("1/2 GB")
                                    }

                                    DeviceText {
                                        source: "assets/memory-card.png"
                                        text: qsTr("Storage")
                                        deviceData: qsTr("8.3/32 GB")
                                    }

                                    DeviceText {
                                        source: "assets/temp.png"
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

                                    DeviceText {
                                        source: "assets/blackberry.png"
                                        text: qsTr("Device")
                                        deviceData: qsTr("Raspberry Pi 4")
                                    }

                                    DeviceText {
                                        source: "assets/blackberry.png"
                                        text: qsTr("Architecture")
                                        deviceData: qsTr("ARM64")
                                    }

                                    DeviceText {
                                        source: "assets/blackberry.png"
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


                                component LogText: Rectangle {
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



                                ScrollView {
                                    id: logsScroll
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    anchors.fill: parent

                                    ColumnLayout {
                                        id: logsColumn
                                        width: parent.width
                                        spacing: 10

                                        DeviceText {
                                            id: logsheader
                                            source: "assets/log.png"
                                            text: "Activity Logs"
                                            deviceData: ""
                                        }

                                        LogText {
                                            source: "assets/info.png"
                                            text: "Dashboard reset"
                                            myDate: "04:03:16 PM"
                                        }

                                        LogText {
                                            source: "assets/info.png"
                                            text: "Update file received"
                                            myDate: "04:04:10 PM"
                                        }

                                        LogText {
                                            source: "assets/info.png"
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
