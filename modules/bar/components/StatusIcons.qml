pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Item bar
    required property Item popouts

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    function shouldOpenOnHover(name: string): bool {
        if (!Config.bar.popouts.statusIcons || !Config.bar.popouts.statusIconsShowOnHover)
            return false;

        switch (name) {
        case "audio":
            return Config.bar.popouts.audioShowOnHover;
        case "network":
        case "ethernet":
            return Config.bar.popouts.networkShowOnHover;
        case "bluetooth":
            return Config.bar.popouts.bluetoothShowOnHover;
        case "battery":
            return Config.bar.popouts.batteryShowOnHover;
        case "kblayout":
            return Config.bar.popouts.kbLayoutShowOnHover;
        case "lockstatus":
            return Config.bar.popouts.lockStatusShowOnHover;
        default:
            return false;
        }
    }

    function shouldHandleClick(name: string): bool {
        if (!Config.bar.popouts.statusIcons)
            return false;

        return !shouldOpenOnHover(name);
    }

    function isActive(names: var): bool {
        if (!root.popouts.hasCurrent || root.popouts.isDetached)
            return false;

        for (let i = 0; i < names.length; i++) {
            if (root.popouts.currentName === names[i])
                return true;
        }

        return false;
    }

    function clickableSegments(): var {
        const segments = [];
        for (let i = 0; i < iconColumn.children.length; i++) {
            const child = iconColumn.children[i];
            if (child.visible && child.segmentClickable)
                segments.push(child);
        }
        return segments;
    }

    function isFirstSegment(segment: Item): bool {
        const segments = clickableSegments();
        return segments.length > 0 && segments[0] === segment;
    }

    function isLastSegment(segment: Item): bool {
        const segments = clickableSegments();
        return segments.length > 0 && segments[segments.length - 1] === segment;
    }

    function openCompactPopout(name: string, segment: Item): void {
        const centerY = segment.mapToItem(root.bar, 0, segment.implicitHeight / 2).y;
        if (root.popouts.hasCurrent && root.popouts.currentName === name && !root.popouts.isDetached) {
            root.popouts.hasCurrent = false;
            return;
        }

        root.popouts.currentName = name;
        root.popouts.currentCenter = centerY;
        root.popouts.hasCurrent = true;
    }

    function handleClick(name: string, segment: Item): void {
        switch (name) {
        case "audio":
            openCompactPopout("audio", segment);
            break;
        case "network":
        case "ethernet":
            openCompactPopout("network", segment);
            break;
        case "bluetooth":
            openCompactPopout("bluetooth", segment);
            break;
        case "battery":
        case "kblayout":
        case "lockstatus":
            openCompactPopout(name, segment);
            break;
        default:
            break;
        }
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    clip: true
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: iconColumn.implicitHeight - (Config.bar.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0)

    ColumnLayout {
        id: iconColumn

        anchors.fill: parent

        spacing: Appearance.spacing.smaller / 2

        SegmentItem {
            segmentId: "lockstatus"
            targetName: "lockstatus"
            activeNames: ["lockstatus"]
            segmentClickable: root.shouldHandleClick("lockstatus")
            visible: Config.bar.status.showLockStatus

            sourceComponent: ColumnLayout {
                spacing: 0

                Item {
                    implicitWidth: capslockIcon.implicitWidth
                    implicitHeight: Hypr.capsLock ? capslockIcon.implicitHeight : 0

                    MaterialIcon {
                        id: capslockIcon

                        anchors.centerIn: parent

                        scale: Hypr.capsLock ? 1 : 0.5
                        opacity: Hypr.capsLock ? 1 : 0

                        text: "keyboard_capslock_badge"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }

                Item {
                    Layout.topMargin: Hypr.capsLock && Hypr.numLock ? iconColumn.spacing : 0

                    implicitWidth: numlockIcon.implicitWidth
                    implicitHeight: Hypr.numLock ? numlockIcon.implicitHeight : 0

                    MaterialIcon {
                        id: numlockIcon

                        anchors.centerIn: parent

                        scale: Hypr.numLock ? 1 : 0.5
                        opacity: Hypr.numLock ? 1 : 0

                        text: "looks_one"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }
            }
        }

        SegmentItem {
            segmentId: "audio-output"
            targetName: "audio"
            activeNames: ["audio"]
            segmentClickable: root.shouldHandleClick("audio")
            visible: Config.bar.status.showAudio
            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        SegmentItem {
            segmentId: "audio-input"
            targetName: "audio"
            activeNames: ["audio"]
            segmentClickable: root.shouldHandleClick("audio")
            visible: Config.bar.status.showMicrophone
            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                color: root.colour
            }
        }

        SegmentItem {
            segmentId: "kblayout"
            targetName: "kblayout"
            activeNames: ["kblayout"]
            segmentClickable: root.shouldHandleClick("kblayout")
            visible: Config.bar.status.showKbLayout
            sourceComponent: StyledText {
                animate: true
                text: Hypr.kbLayout
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }

        SegmentItem {
            segmentId: "network"
            targetName: "network"
            activeNames: ["network"]
            segmentClickable: root.shouldHandleClick("network")
            visible: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)
            sourceComponent: MaterialIcon {
                animate: true
                text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        SegmentItem {
            segmentId: "ethernet"
            targetName: "ethernet"
            activeNames: ["network", "ethernet"]
            segmentClickable: root.shouldHandleClick("ethernet")
            visible: Config.bar.status.showNetwork && Nmcli.activeEthernet
            sourceComponent: MaterialIcon {
                animate: true
                text: "cable"
                color: root.colour
            }
        }

        SegmentItem {
            segmentId: "bluetooth"
            targetName: "bluetooth"
            activeNames: ["bluetooth"]
            segmentClickable: root.shouldHandleClick("bluetooth")
            visible: Config.bar.status.showBluetooth
            sourceComponent: Item {
                implicitWidth: bluetoothIcon.implicitWidth
                implicitHeight: bluetoothIcon.implicitHeight

                MaterialIcon {
                    id: bluetoothIcon

                    anchors.centerIn: parent
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled)
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected))
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
            }

            DeviceIndicator {
                visible: Config.bar.status.showBluetooth
                itemName: "bluetooth"
            }
        }

        SegmentItem {
            segmentId: "battery"
            targetName: "battery"
            activeNames: ["battery"]
            segmentClickable: root.shouldHandleClick("battery")
            visible: Config.bar.status.showBattery
            sourceComponent: MaterialIcon {
                animate: true
                text: {
                    if (!UPower.displayDevice.isLaptopBattery) {
                        if (PowerProfiles.profile === PowerProfile.PowerSaver)
                            return "energy_savings_leaf";
                        if (PowerProfiles.profile === PowerProfile.Performance)
                            return "rocket_launch";
                        return "balance";
                    }

                    const perc = UPower.displayDevice.percentage;
                    const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                    if (perc === 1)
                        return charging ? "battery_charging_full" : "battery_full";
                    let level = Math.floor(perc * 7);
                    if (charging && (level === 4 || level === 1))
                        level--;
                    return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                }
                color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                fill: 1
            }
        }
    }

    component SegmentItem: Item {
        id: segment

        required property string segmentId
        required property string targetName
        required property var activeNames
        required property Component sourceComponent
        property bool segmentClickable: true
        property string name: targetName
        readonly property real edgeInset: Math.max(Appearance.padding.normal, root.implicitWidth / 2 - content.implicitHeight / 2)
        readonly property real topInset: root.isFirstSegment(segment) ? edgeInset : 0
        readonly property real bottomInset: root.isLastSegment(segment) ? edgeInset : 0

        Layout.fillWidth: visible
        implicitWidth: root.implicitWidth
        implicitHeight: content.implicitHeight + topInset + bottomInset

        SegmentBackground {
            anchors.fill: parent
            active: root.isActive(segment.activeNames)
            pressed: stateLayer.pressed
            roundTop: root.isFirstSegment(segment)
            roundBottom: root.isLastSegment(segment)
        }

        Loader {
            id: content

            anchors.top: parent.top
            anchors.topMargin: segment.topInset
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: segment.sourceComponent
        }

        StateLayer {
            id: stateLayer

            anchors.fill: parent
            showHoverBackground: false
            enabled: segment.visible && segment.segmentClickable
            function onClicked(): void {
                root.handleClick(segment.targetName, segment);
            }
        }
    }

    component DeviceIndicator: Item {
        id: deviceRow

        required property BluetoothDevice modelData
        property string itemName: ""
        property bool segmentClickable: false
        property string name: itemName

        Layout.fillWidth: visible
        implicitWidth: root.implicitWidth
        implicitHeight: deviceIcon.implicitHeight

        MaterialIcon {
            id: deviceIcon

            anchors.centerIn: parent
            animate: true
            text: Icons.getBluetoothIcon(deviceRow.modelData?.icon)
            color: root.colour
            fill: 1

            SequentialAnimation on opacity {
                running: deviceRow.modelData?.state !== BluetoothDeviceState.Connected
                alwaysRunToEnd: true
                loops: Animation.Infinite

                Anim {
                    from: 1
                    to: 0
                    duration: Appearance.anim.durations.large
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
                Anim {
                    from: 0
                    to: 1
                    duration: Appearance.anim.durations.large
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }
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
