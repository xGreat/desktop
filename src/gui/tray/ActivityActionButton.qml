import QtQuick 2.5
import QtQuick.Controls 2.3
import Style 1.0

Item {
    id: root
    readonly property bool labelVisible: label.visible
    readonly property bool iconVisible: icon.visible

    // label value
    property string text: ""

    // icon value
    property string imageSource: ""

    // icon value hovered
    property string imageSourceHover: ""

    // Tooltip value
    property string tooltipText: ""

    // text color
    property color textColor: Style.ncTextColor
    property color textColorHovered: Style.lightHover

    // icon background color
    property color bgColor: Style.ncBlue

    // text border color
    property color textBorderColor: "transparent"

    signal clicked()

    Loader {
        active: root.isDismissAction === true

        anchors.fill: parent

        sourceComponent: CustomTextButton {
             anchors.fill: parent
             onClicked: root.clicked()
             text: root.text
             tooltipText: root.tooltipText
        }
    }

    Loader {
        active: root.isDismissAction === false

        anchors.fill: parent

        sourceComponent: CustomButton {
            id: customButton

            text: root.text

            anchors.fill: parent

            imageSource: root.imageSource

            imageSourceHover: root.imageSourceHover

            textColor: root.textColor
            textColorHovered: root.textColorHovered

            textBorderColor: root.textBorderColor

            bgColor: root.bgColor

            tooltipText: root.tooltipText

            onClicked: root.clicked()
        }
    }
}
