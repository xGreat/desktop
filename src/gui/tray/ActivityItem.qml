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
        }
        RowLayout {
            id: activityActionsLayout
            Layout.preferredHeight: Style.trayWindowHeaderHeight
            Layout.leftMargin: 20
            Layout.fillHeight: true

            spacing: 20

            function actionButtonIcon(actionIndex, color) {
                const verb = String(model.links[actionIndex].verb);
                if (verb === "WEB" && (model.objectType === "chat" || model.objectType === "call")) {
                    return "image://svgimage-custom-color/reply.svg" + "/" + color;
                } else if (verb === "DELETE") {
                    return "image://svgimage-custom-color/close.svg" + "/" + color;
                }

                return "image://svgimage-custom-color/confirm.svg" + "/" + color;
            }

            function actionButtonText(actionIndex) {
                const verb = String(model.links[actionIndex].verb);
                if (verb === "DELETE") {
                    return qsTr("Mark as read")
                } else if (verb === "WEB" && (model.objectType === "chat" || model.objectType !== "call")) {
                    return qsTr("Reply")
                }

                return model.links[actionIndex].label;
            }

            Repeater {
                model: activityItem.links.length > maxActionButtons ? 1 : activityItem.links.length

                ActivityActionButton {
                    id: activityActionButton

                    readonly property int actionIndex: model.index
                    readonly property bool primary: model.index === 0 && String(activityItem.links[actionIndex].verb) !== "DELETE"

                    readonly property bool isDismissAction: String(activityItem.links[actionIndex].verb) === "DELETE"

                    Layout.fillHeight: true

                    text: activityActionsLayout.actionButtonText(actionIndex)

                    imageSource: activityActionsLayout.actionButtonIcon(actionIndex, Style.ncBlue)

                    imageSourceHover: activityActionsLayout.actionButtonIcon(actionIndex, Style.ncTextColor)

                    textColor: primary ? Style.ncBlue : "black"
                    textColorHovered: Style.lightHover

                    tooltipText: activityItem.links[actionIndex].label

                    Layout.minimumWidth: primary ? 100 : 80
                    Layout.minimumHeight: parent.height

                    Layout.preferredWidth: primary ? -1 : parent.height

                    onClicked: activityModel.triggerAction(activityItem.itemIndex, actionIndex)
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

            Rectangle {
                id: moreActionsButton

                color: activityHover.color

                Rectangle {
                    id: mouseAreaHover
                    color: moreActionsButtonMouseArea.containsMouse ? "white" : moreActionsButton.color
                    anchors.fill: moreActionsButtonIcon
                }

                Layout.preferredWidth: 32
                Layout.minimumWidth: 32
                Layout.fillHeight: true

                signal clicked()

                Image {
                    id: moreActionsButtonIcon
                    source: "qrc:///client/theme/more.svg"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    width: 24
                    height: 24
                    anchors.centerIn: parent
                }

                visible: displayActions && ((path !== "") || (activityItem.links.length > maxActionButtons))

                ToolTip.visible: hovered
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.text: qsTr("Show more actions")

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Show more actions")
                Accessible.onPressAction: moreActionsButton.clicked()

                MouseArea {
                    id: moreActionsButtonMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.clicked()
                }

                onClicked:  moreActionsButtonContextMenu.popup();

                Connections {
                    target: flickable

                    function onMovementStarted() {
                        moreActionsButtonContextMenu.close();
                    }
                }

                Container {
                    id: moreActionsButtonContextMenuContainer
                    visible: moreActionsButtonContextMenu.opened

                    width: moreActionsButtonContextMenu.width
                    height: moreActionsButtonContextMenu.height
                    anchors.right: moreActionsButton.right
                    anchors.top: moreActionsButton.top

                    Menu {
                        id: moreActionsButtonContextMenu
                        anchors.centerIn: parent

                        // transform model to contain indexed actions with primary action filtered out
                        function actionListToContextMenuList(actionList) {
                            // early out with non-altered data
                            if (activityItem.links.length <= maxActionButtons) {
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
                            onClicked: fileActivityButtonClicked(absolutePath)
                        }

                        Repeater {
                            id: moreActionsButtonContextMenuRepeater

                            model: moreActionsButtonContextMenu.actionListToContextMenuList(activityItem.links)

                            delegate: MenuItem {
                                id: moreActionsButtonContextMenuEntry
                                text: model.modelData.label
                                onTriggered: activityModel.triggerAction(activityItem.itemIndex, model.modelData.actionIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}
