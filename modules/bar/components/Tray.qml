pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    required property Item bar
    required property Item popouts

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Appearance.padding.normal : Appearance.padding.small
    readonly property int spacing: Config.bar.tray.background ? Appearance.spacing.small : 0

    property bool expanded

    readonly property real nonAnimHeight: {
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        return (expanded ? expandIcon.implicitHeight + layout.implicitHeight + spacing : expandIcon.implicitHeight) + padding * 2;
    }

    clip: true
    visible: height > 0

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    Column {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        spacing: Appearance.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !Config.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {
                bar: root.bar
                popouts: root.popouts
                tray: root
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Loader {
        id: expandIcon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: root.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Appearance.padding.small * 2

            SegmentBackground {
                anchors.fill: parent
                active: root.expanded
                pressed: expandStateLayer.pressed
                roundTop: !root.expanded
                roundBottom: true
            }

            StateLayer {
                id: expandStateLayer

                anchors.fill: parent
                showHoverBackground: false
                enabled: Config.bar.popouts.tray && !Config.bar.popouts.trayShowOnHover

                function onClicked(): void {
                    root.expanded = !root.expanded;
                }
            }

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Appearance.padding.small : -Appearance.padding.small
                text: "expand_less"
                font.pointSize: Appearance.font.size.large
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
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
