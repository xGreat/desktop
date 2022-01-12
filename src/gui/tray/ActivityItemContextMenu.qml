import QtQml 2.15
import QtQuick 2.15
import QtQuick.Controls 2.3

Item {
    id: root

    property int maxActionButtons: 0

    property var activityItemLinks: []

    property alias opened: moreActionsButtonContextMenu.opened

    function open() {
        moreActionsButtonContextMenu.popup()
    }

    function close() {
        moreActionsButtonContextMenu.close()
    }

    visible: moreActionsButtonContextMenu.opened

    width: moreActionsButtonContextMenu.width
    height: moreActionsButtonContextMenu.height

    signal menuEntryTriggered(int index)

    signal fileActivityButtonClicked()

    Menu {
        id: moreActionsButtonContextMenu
        anchors.centerIn: parent

        // transform model to contain indexed actions with primary action filtered out
        function actionListToContextMenuList(actionList) {
            // early out with non-altered data
            if (actionList.length <= maxActionButtons) {
                return actionList;
            }

            // add index to every action and filter 'primary' action out
            var reducedActionList = actionList.reduce(function(reduced, action, index) {
                if (!action.primary) {
                    var actionWithIndex = { actionIndex: index, label: action.label };
                    reduced.push(actionWithIndex);
                }
                return reduced;
            }, []);


            return reducedActionList;
        }

        MenuItem {
            text: qsTr("View activity")
            onClicked: root.fileActivityButtonClicked()
        }

        Repeater {
            id: moreActionsButtonContextMenuRepeater

            model: moreActionsButtonContextMenu.actionListToContextMenuList(root.activityItemLinks)

            delegate: MenuItem {
                id: moreActionsButtonContextMenuEntry
                text: model.modelData.label
                onTriggered: root.menuEntryTriggered(model.modelData.actionIndex)
            }
        }
    }
}
