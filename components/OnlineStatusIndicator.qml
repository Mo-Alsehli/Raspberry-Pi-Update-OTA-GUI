import QtQuick


Rectangle {
    id: root
    property bool connected: false
    width: 10
    height: 10
    radius: 5
    anchors.verticalCenter: parent.verticalCenter
    color: connected ? "#22c553" : "#dad7cd"
}
