pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    required property Item popouts
    property color colour: Colours.palette.m3primary

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        // Length - 2 cause repeater counts as a child
        return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1
    readonly property bool active: popouts.hasCurrent && !popouts.isDetached && popouts.currentName === "activewindow"

    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    SegmentBackground {
        anchors.fill: parent
        active: root.active
        pressed: stateLayer.pressed
        roundTop: true
        roundBottom: true
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - icon.height

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    StateLayer {
        id: stateLayer

        anchors.fill: parent
        showHoverBackground: false
        enabled: Config.bar.popouts.activeWindow && !Config.bar.popouts.activeWindowShowOnHover

        function onClicked(): void {
            const centerY = root.mapToItem(root.bar, 0, root.implicitHeight / 2).y;
            if (root.popouts.hasCurrent && root.popouts.currentName === "activewindow" && !root.popouts.isDetached) {
                root.popouts.hasCurrent = false;
                return;
            }

            root.popouts.currentName = "activewindow";
            root.popouts.currentCenter = centerY;
            root.popouts.hasCurrent = true;
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: root.current === this ? 1 : 0

        transform: [
            Translate {
                x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {}
        }
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
