pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int vPadding: Appearance.padding.large

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item?.enabled && item.id === "tray") {
                item.item.expanded = false;
            }
        }
    }

    function shouldOpenStatusIconOnHover(name: string): bool {
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

    function openCompactPopout(name: string, centerY: real): void {
        if (popouts.hasCurrent && popouts.currentName === name && !popouts.isDetached) {
            popouts.hasCurrent = false;
            return;
        }

        popouts.currentName = name;
        popouts.currentCenter = centerY;
        popouts.hasCurrent = true;
    }

    function openStatusIconClickTarget(name: string, centerY: real): void {
        if (!Config.bar.popouts.statusIcons)
            return;

        switch (name) {
        case "audio":
            openCompactPopout("audio", centerY);
            break;
        case "network":
        case "ethernet":
            openCompactPopout("network", centerY);
            break;
        case "bluetooth":
            openCompactPopout("bluetooth", centerY);
            break;
        case "battery":
        case "kblayout":
        case "lockstatus":
            openCompactPopout(name, centerY);
            break;
        default:
            break;
        }
    }

    function resolveStatusIcon(y: real): var {
        const statusIcons = childAt(width / 2, y) as WrappedLoader;
        if (!statusIcons || statusIcons.id !== "statusIcons")
            return null;

        const items = statusIcons.item.items;
        const localY = mapToItem(items, 0, y).y;

        for (let i = 0; i < items.children.length; i++) {
            const child = items.children[i];
            if (!child?.visible)
                continue;

            const childHeight = child.height > 0 ? child.height : child.implicitHeight;
            if (localY >= child.y && localY <= child.y + childHeight)
                return child;
        }

        return null;
    }

    function handleClick(y: real): void {
        const ch = childAt(width / 2, y) as WrappedLoader;
        if (!ch)
            return;

        const id = ch.id;
        const item = ch.item;

        if (id === "activeWindow" && Config.bar.popouts.activeWindow && !Config.bar.popouts.activeWindowShowOnHover) {
            openCompactPopout("activewindow", item.mapToItem(root, 0, item.implicitHeight / 2).y);
            return;
        }

        if (id === "tray" && Config.bar.popouts.tray && !Config.bar.popouts.trayShowOnHover) {
            if (Config.bar.tray.compact && !item.expanded && item.expandIcon.contains(mapToItem(item.expandIcon, item.implicitWidth / 2, y))) {
                item.expanded = true;
            }
            return;
        }

        if (id !== "statusIcons" || !Config.bar.popouts.statusIcons)
            return;

        const icon = resolveStatusIcon(y);
        if (!icon)
            return;

        if (Config.bar.popouts.statusIconsShowOnHover && shouldOpenStatusIconOnHover(icon.name))
            return;

        const centerY = icon.mapToItem(root, 0, (icon.item?.implicitHeight ?? icon.implicitHeight) / 2).y;
        openStatusIconClickTarget(icon.name, centerY);
    }

    function checkPopout(y: real): void {
        const ch = childAt(width / 2, y) as WrappedLoader;

        if (ch?.id !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.id;
        const top = ch.y;
        const item = ch.item;
        const itemHeight = item.implicitHeight;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const icon = resolveStatusIcon(y);
            if (icon && shouldOpenStatusIconOnHover(icon.name)) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "tray" && Config.bar.popouts.tray && Config.bar.popouts.trayShowOnHover) {
            if (!Config.bar.tray.compact || (item.expanded && !item.expandIcon.contains(mapToItem(item.expandIcon, item.implicitWidth / 2, y)))) {
                const index = Math.floor(((y - top - item.padding * 2 + item.spacing) / item.layout.implicitHeight) * item.items.count);
                const trayItem = item.items.itemAt(index);
                if (trayItem) {
                    popouts.currentName = `traymenu${index}`;
                    popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y);
                    popouts.hasCurrent = true;
                } else {
                    popouts.hasCurrent = false;
                }
            } else {
                popouts.hasCurrent = false;
                item.expanded = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.popouts.activeWindowShowOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = item.mapToItem(root, 0, itemHeight / 2).y;
            popouts.hasCurrent = true;
        } else {
            popouts.hasCurrent = false;
        }
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y) as WrappedLoader;
        if (ch?.id === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = (Config.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(`togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || (Config.bar.workspaces.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (y < screen.height / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + Config.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - Config.services.brightnessIncrement);
        }
    }

    spacing: Appearance.spacing.normal

    Repeater {
        id: repeater

        model: Config.bar.entries

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: WrappedLoader {
                    Layout.fillHeight: enabled
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: WrappedLoader {
                    sourceComponent: OsIcon {}
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: WrappedLoader {
                    sourceComponent: Workspaces {
                        screen: root.screen
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: WrappedLoader {
                    sourceComponent: ActiveWindow {
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                        popouts: root.popouts
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: WrappedLoader {
                    sourceComponent: Tray {
                        bar: root
                        popouts: root.popouts
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: WrappedLoader {
                    sourceComponent: Clock {}
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: WrappedLoader {
                    sourceComponent: StatusIcons {
                        bar: root
                        popouts: root.popouts
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: WrappedLoader {
                    sourceComponent: Power {
                        visibilities: root.visibilities
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool enabled
        required property string id
        required property int index

        function findFirstEnabled(): Item {
            const count = repeater.count;
            for (let i = 0; i < count; i++) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        function findLastEnabled(): Item {
            for (let i = repeater.count - 1; i >= 0; i--) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        Layout.alignment: Qt.AlignHCenter

        // Cursed ahh thing to add padding to first and last enabled components
        Layout.topMargin: findFirstEnabled() === this ? root.vPadding : 0
        Layout.bottomMargin: findLastEnabled() === this ? root.vPadding : 0

        visible: enabled
        active: enabled
    }
}
