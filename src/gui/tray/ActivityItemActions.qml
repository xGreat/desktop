import QtQml 2.12
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import Style 1.0
import com.nextcloud.desktopclient 1.0

RowLayout {
    id: root

    property var activityActionLinks: []

    property string objectType: ""

    property color moreActionsButtonColor: "white"

    property int maxActionButtons: 0

    property bool displayActions: false

    property string path: ""

    property string absolutePath: ""

    property Flickable flickable: Flickable{}

    signal fileActivityButtonClicked(string absolutePath)
    signal triggerAction(int actionIndex)

    spacing: 20

    function actionButtonIcon(actionIndex, color) {
        const verb = String(root.activityActionLinks[actionIndex].verb);
        if (verb === "WEB" && (root.objectType === "chat" || root.objectType === "call")) {
            return "image://svgimage-custom-color/reply.svg" + "/" + color;
        } else if (verb === "DELETE") {
            return "image://svgimage-custom-color/close.svg" + "/" + color;
        }

        return "image://svgimage-custom-color/confirm.svg" + "/" + color;
    }

    function actionButtonText(actionIndex) {
        const verb = String(root.activityActionLinks[actionIndex].verb);
        if (verb === "DELETE") {
            return qsTr("Mark as read")
        } else if (verb === "WEB" && (root.objectType === "chat" || root.objectType !== "call")) {
            return qsTr("Reply")
        }

        return root.activityActionLinks[actionIndex].label;
    }

    Repeater {
        model: root.activityActionLinks.length > root.maxActionButtons ? 1 : root.activityActionLinks.length

        ActivityActionButton {
            id: activityActionButton

            readonly property int actionIndex: model.index
            readonly property bool primary: model.index === 0 && String(root.activityActionLinks[actionIndex].verb) !== "DELETE"

            readonly property bool isDismissAction: String(root.activityActionLinks[actionIndex].verb) === "DELETE"

            Layout.fillHeight: true

            text: root.actionButtonText(actionIndex)

            imageSource: root.actionButtonIcon(actionIndex, Style.ncBlue)

            imageSourceHover: root.actionButtonIcon(actionIndex, Style.ncTextColor)

            textColor: primary ? Style.ncBlue : "black"
            textColorHovered: Style.lightHover

            tooltipText: root.activityActionLinks[actionIndex].label

            Layout.minimumWidth: primary ? 100 : 80
            Layout.minimumHeight: parent.height

            Layout.preferredWidth: primary ? -1 : parent.height

            onClicked: root.triggerAction(actionIndex)
        }

    }

    Rectangle {
        id: moreActionsButton

        property alias hovered: moreActionsButtonMouseArea.containsMouse


        color: root.moreActionsButtonColor

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

        visible: root.displayActions && ((root.path !== "") || (root.activityActionLinks.length > root.maxActionButtons))

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

        onClicked:  moreActionsButtonContextMenuContainer.open();

        Connections {
            target: root.flickable

            function onMovementStarted() {
                moreActionsButtonContextMenuContainer.close();
            }
        }

        ActivityItemContextMenu {
            id: moreActionsButtonContextMenuContainer

            visible: moreActionsButtonContextMenu.opened

            width: moreActionsButtonContextMenu.width
            height: moreActionsButtonContextMenu.height
            anchors.right: moreActionsButton.right
            anchors.top: moreActionsButton.top

            maxActionButtons: root.maxActionButtons
            activityItemLinks: root.activityActionLinks

            onMenuEntryTriggered: function(entryIndex) {
                root.triggerAction(entryIndex)
            }

            onFileActivityButtonClicked: root.fileActivityButtonClicked(root.absolutePath)
        }
    }
}
