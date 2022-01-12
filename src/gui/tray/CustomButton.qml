import QtQuick 2.5
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.2
import Style 1.0

Item {
    id: root
    readonly property bool labelVisible: label.visible
    readonly property bool iconVisible: icon.visible

    // label value
    property string text: ""

    // font value
    property var font: label.font

    // icon value
    property string imageSource: ""

    // icon value hovered
    property string imageSourceHover: ""

    // Tooltip value
    property string tooltipText: ""

    // text color
    property color textColor: Style.ncTextColor
    property color textColorHovered: Style.lightHover

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
    Accessible.name: text !== "" ? text : (tooltipText !== "" ? tooltipText : qsTr("Activity action button"))
    Accessible.onPressAction: clicked()

    Rectangle {
        id: buttonBackground
        color: root.hovered ? root.bgColor : "lightblue"

        anchors.topMargin: 10
        anchors.bottomMargin: 10

        anchors.fill: root

        radius: 25

        RowLayout {
            id: mainLayout

            anchors.fill: parent
            // background with border around the Text
            // icon
            Image {
                id: icon
                visible: root.imageSource !== "" && root.imageSourceHover !== ""
                source: root.hovered ? root.imageSourceHover : root.imageSource
                sourceSize.width: 24
                sourceSize.height: 24
                width: 16
                height: 16
                Layout.leftMargin: 10
                Layout.rightMargin: !label.visible ? 10 : 0
            }

            // label
            Label {
                id: label
                visible: root.text !== ""
                text: root.text
                font: root.font
                color: root.hovered ? root.textColorHovered : root.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.leftMargin: !icon.visible ? 10 : 0
                Layout.fillWidth: true
                Layout.rightMargin: 10
            }

            ToolTip {
                text: root.tooltipText
                delay: 1000
                visible: root.tooltipText != "" && root.hovered
            }

            Accessible.role: Accessible.Button
            Accessible.name: root.text !== "" ? root.text : (root.tooltipText !== "" ? root.tooltipText : qsTr("Activity action button"))
            Accessible.onPressAction: root.clicked()

        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: buttonBackground
        onClicked: root.clicked()
        hoverEnabled: true
    }
}
