import QtQml 2.12
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import Style 1.0
import com.nextcloud.desktopclient 1.0

MouseArea {
    id: activityMouseArea

    readonly property int maxActionButtons: 2
    property Flickable flickable


    height: (activityItem.links.length > 0 || shareButton) ? Style.trayWindowHeaderHeight * 2 : Style.trayWindowHeaderHeight

    signal fileActivityButtonClicked(string absolutePath)

    enabled: (path !== "" || link !== "")
    hoverEnabled: true

    Rectangle {
        id: activityHover
        anchors.fill: parent
        color: (parent.containsMouse ? Style.lightHover : "transparent")
    }

    ColumnLayout {
        width: activityMouseArea.width
        spacing: 0
        RowLayout {
            id: activityItem

            readonly property variant links: model.links

            readonly property int itemIndex: model.index

            Layout.fillWidth: true
            Layout.preferredHeight: Style.trayWindowHeaderHeight
            spacing: 0

            Accessible.role: Accessible.ListItem
            Accessible.name: path !== "" ? qsTr("Open %1 locally").arg(displayPath)
                                         : message
            Accessible.onPressAction: activityMouseArea.clicked()

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
                    text: (type === "Activity" || type === "Notification") ? subject : message
                    width: parent.width
                    elide: Text.ElideRight
                    font.pixelSize: Style.topLinePixelSize
                    color: activityTextTitleColor
                }

                Text {
                    id: activityTextInfo
                    text: (type === "Sync") ? displayPath
                                            : (type === "File") ? subject
                                                                : (type === "Notification") ? message
                                                                                            : ""
                    height: (text === "") ? 0 : activityTextTitle.height
                    width: parent.width
                    elide: Text.ElideRight
                    font.pixelSize: Style.subLinePixelSize
                }

                Text {
                    id: activityTextDateTime
                    text: dateTime
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
                Accessible.name: qsTr("Share %1").arg(displayPath)
                Accessible.onPressAction: shareButton.clicked()
            }
        }

        ActivityItemActions {
            id: activityActionsLayout
            Layout.preferredHeight: Style.trayWindowHeaderHeight
            Layout.leftMargin: 20
            Layout.fillHeight: true

            activityActionLinks: model.links
            objectType: model.objectType
            moreActionsButtonColor: activityHover.color
            maxActionButtons: activityMouseArea.maxActionButtons
            displayActions: model.displayActions
            flickable: activityMouseArea.flickable
            path: model.path
            absolutePath: model.absolutePath

            onTriggerAction: function(actionIndex) {
                root.triggerAction(activityItem.itemIndex, actionIndex)
            }

            onFileActivityButtonClicked: function(absolutePath) {
                activityMouseArea.fileActivityButtonClicked(absolutePath)
            }
        }
    }
}
