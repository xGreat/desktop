import QtQuick 2.5
import QtQuick.Controls 2.3
import Style 1.0

Item {
    id: root
    readonly property bool labelVisible: label.visible
    readonly property bool iconVisible: icon.visible

    // label value
    property string text: "Mark as read"

    // icon value
    property string imageSource: ""

    // icon value hovered
    property string imageSourceHover: ""

    // Tooltip value
    property string tooltipText: ""

    // text color
    property color textColor: Style.unifiedSearchResulSublineColor
    property color textColorHovered: "black"

    // text background color
    property color bgColor: "transparent"

    // icon background color
    property color iconBgColor: Style.ncBlue
    property color iconBgColorHovered: Style.lightHover

    // text border color
    property color textBorderColor: "transparent"

    property alias hovered: mouseArea.containsMouse

    signal clicked()

    Accessible.role: Accessible.Button
    Accessible.name: root.text !== "" ? root.text : (root.tooltipText !== "" ? root.tooltipText : qsTr("Activity action button"))
    Accessible.onPressAction: clicked()

    Label {
        id: label
        visible: root.text !== ""
        text: root.text
        font.underline: true
        color: root.hovered ? root.textColorHovered : root.textColor
        anchors.fill: parent
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    ToolTip {
        text: root.tooltipText
        delay: 1000
        visible: root.tooltipText != "" && root.hovered
    }

    MouseArea {
        id: mouseArea
        anchors.fill: label
        onClicked: root.clicked()
        hoverEnabled: true
    }
}
