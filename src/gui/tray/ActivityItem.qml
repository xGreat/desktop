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


    height: (model.links.length > 0 || model.path !== "") ? Style.trayWindowHeaderHeight * 2 : Style.trayWindowHeaderHeight

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

        ActivityItemContent {
            id: activityContent

            activityData: model

            onClicked: activityMouseArea.clicked()

            onShareButtonClicked: Systray.openShareDialog(model.displayPath, model.absolutePath)

            Layout.fillWidth: true
            Layout.preferredHeight: Style.trayWindowHeaderHeight

            Accessible.role: Accessible.ListItem
            Accessible.name: path !== "" ? qsTr("Open %1 locally").arg(model.displayPath)
                                         : model.message
            Accessible.onPressAction: activityMouseArea.clicked()
        }

        ActivityItemActions {
            id: activityActions
            Layout.preferredHeight: Style.trayWindowHeaderHeight
            Layout.leftMargin: 20
            Layout.fillHeight: true

            activityData: model

            moreActionsButtonColor: activityHover.color
            maxActionButtons: activityMouseArea.maxActionButtons
            flickable: activityMouseArea.flickable

            onTriggerAction: function(actionIndex) {
                activityModel.triggerAction(model.index, actionIndex)
            }

            onFileActivityButtonClicked: function(absolutePath) {
                activityMouseArea.fileActivityButtonClicked(absolutePath)
            }
        }
    }
}
