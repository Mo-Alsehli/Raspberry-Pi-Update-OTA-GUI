import QtQuick
import QtQuick.Effects

MultiEffect {
    id: root

    property Item target

    source: target
    shadowBlur: 1.0
    shadowEnabled: true
    shadowColor: "#22000000"
    shadowVerticalOffset: 10
    shadowHorizontalOffset: 7
}
