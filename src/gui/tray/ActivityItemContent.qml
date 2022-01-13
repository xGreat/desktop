import QtQml 2.12
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import Style 1.0
import com.nextcloud.desktopclient 1.0

RowLayout {
    id: root

    property variant activityData: ({})

    property color activityTextTitleColor: Style.ncTextColor

    signal clicked()

    signal shareButtonClicked()

    spacing: 0

    Image {
        id: activityIcon
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.leftMargin: 20
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        verticalAlignment: Qt.AlignCenter
        source: icon
        sourceSize.height: 64
        sourceSize.width: 64
    }

    Column {
        id: activityTextColumn
        Layout.leftMargin: 14
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.fillWidth: true
        spacing: 4
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

        Text {
            id: activityTextTitle
            text: (root.activityData.type === "Activity" || root.activityData.type === "Notification") ? root.activityData.subject : root.activityData.message
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.topLinePixelSize
            color: root.activityData.activityTextTitleColor
        }

        Text {
            id: activityTextInfo
            text: (root.activityData.type === "Sync") ? root.activityData.displayPath
                                    : (root.activityData.type === "File") ? root.activityData.subject
                                                        : (root.activityData.type === "Notification") ? root.activityData.message
                                                                                    : ""
            height: (text === "") ? 0 : activityTextTitle.height
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.subLinePixelSize
        }

        Text {
            id: activityTextDateTime
            text: root.activityData.dateTime
            height: (text === "") ? 0 : activityTextTitle.height
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.subLinePixelSize
            color: "#808080"
        }
    }
    CustomButton {
        id: shareButton

        visible: root.activityData.isShareable

        imageSource: "image://svgimage-custom-color/share.svg" + "/" + Style.ncBlue

        imageSourceHover: "image://svgimage-custom-color/share.svg" + "/" + Style.ncTextColor

        tooltipText: qsTr("Open share dialog")

        bgColor: Style.ncBlue

        Layout.minimumWidth: 50
        Layout.minimumHeight: parent.height
        Layout.preferredWidth: -1

        onClicked: root.shareButtonClicked()

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Share %1").arg(root.activityData.displayPath)
        Accessible.onPressAction: shareButton.clicked()
    }
}
