import QtQml 2.12
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import Style 1.0
import com.nextcloud.desktopclient 1.0

RowLayout {
    id: root

    property variant links: []

    property int itemIndex: 0

    property string displayPath: ""

    property string message: ""

    property string subject: ""

    property string dateTime: ""

    property string type: ""

    property bool isShareable: false

    property color activityTextTitleColor: Style.ncTextColor

    signal clicked()

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
            text: (root.type === "Activity" || root.type === "Notification") ? root.subject : root.message
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.topLinePixelSize
            color: activityTextTitleColor
        }

        Text {
            id: activityTextInfo
            text: (root.type === "Sync") ? root.displayPath
                                    : (root.type === "File") ? root.subject
                                                        : (root.type === "Notification") ? root.message
                                                                                    : ""
            height: (text === "") ? 0 : activityTextTitle.height
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.subLinePixelSize
        }

        Text {
            id: activityTextDateTime
            text: root.dateTime
            height: (text === "") ? 0 : activityTextTitle.height
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Style.subLinePixelSize
            color: "#808080"
        }
    }
    CustomButton {
        id: shareButton

        visible: isShareable

        imageSource: "image://svgimage-custom-color/share.svg" + "/" + Style.ncBlue

        imageSourceHover: "image://svgimage-custom-color/share.svg" + "/" + Style.ncTextColor

        tooltipText: qsTr("Open share dialog")

        bgColor: Style.ncBlue

        Layout.minimumWidth: 50
        Layout.minimumHeight: parent.height
        Layout.preferredWidth: -1

        onClicked: root.clicked()

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Share %1").arg(root.displayPath)
        Accessible.onPressAction: shareButton.clicked()
    }
}
