pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property Item bar
    required property SystemTrayItem modelData
    required property Item popouts
    required property int index
    required property Item tray

    readonly property bool active: root.popouts.hasCurrent && !root.popouts.isDetached && root.popouts.currentName === `traymenu${index}`

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: Appearance.font.size.small * 2

    SegmentBackground {
        anchors.fill: parent
        active: root.active
        pressed: mouse.pressed
        roundTop: root.index === 0
        roundBottom: !Config.bar.tray.compact && root.index === root.tray.items.count - 1
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onClicked: event => {
            if (event.button === Qt.LeftButton && Config.bar.popouts.tray && !Config.bar.popouts.trayShowOnHover) {
                root.popouts.currentName = `traymenu${index}`;
                root.popouts.currentCenter = root.mapToItem(root.bar, 0, root.height / 2).y;
                root.popouts.hasCurrent = true;
            } else if (event.button === Qt.LeftButton) {
                modelData.activate();
            } else {
                modelData.secondaryActivate();
            }
        }
    }

    ColouredIcon {
        id: icon

        anchors.centerIn: parent
        implicitWidth: Appearance.font.size.small * 2
        implicitHeight: Appearance.font.size.small * 2
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }

    component SegmentBackground: Item {
        id: segmentBg

        property bool active
        property bool pressed
        property bool roundTop: true
        property bool roundBottom: true
        property color activeColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        property color pressedColor: Qt.alpha(Colours.palette.m3onSurface, 0.12)
        readonly property color fillColor: active ? activeColor : pressed ? pressedColor : "transparent"
        readonly property real cornerRadius: Math.min(Math.min(width / 2, height / 2), Appearance.rounding.full)

        clip: true

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            y: segmentBg.roundTop ? 0 : -segmentBg.cornerRadius
            height: parent.height + (segmentBg.roundTop ? 0 : segmentBg.cornerRadius) + (segmentBg.roundBottom ? 0 : segmentBg.cornerRadius)
            radius: segmentBg.cornerRadius
            color: segmentBg.fillColor
        }
    }
}
