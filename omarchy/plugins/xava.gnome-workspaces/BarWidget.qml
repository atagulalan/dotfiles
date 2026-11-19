import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// A compact GNOME-style indicator for the workspaces that actually exist on
// this bar's monitor. This fits the dynamic workspaces created by
// ~/.config/hypr/macos-fullscreen.lua: the dots appear and disappear with the
// fullscreen application workspaces instead of reserving numbered empty slots.
BarWidget {
  id: root
  moduleName: "xava.gnome-workspaces"

  readonly property var barWindow: root.QsWindow ? root.QsWindow.window : null
  readonly property var monitor: barWindow && barWindow.screen
    ? Hyprland.monitorFor(barWindow.screen) : null
  readonly property string activeWorkspaceName:
    root.monitor && root.monitor.activeWorkspace
      ? String(root.monitor.activeWorkspace.name) : ""
  readonly property color indicatorColor:
    root.bar ? root.bar.barForeground : Color.foreground

  readonly property real activeWidth: Style.spaceReal(30)
  readonly property real activeHeight: Style.spaceReal(10)
  readonly property real dotSize: Style.spaceReal(7)
  readonly property real indicatorSpacing: Style.spaceReal(7)
  readonly property real horizontalPadding: Style.spaceReal(6)

  property real wheelAccumulator: 0

  function workspacesForMonitor() {
    if (!root.monitor) return []

    var result = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      var name = String(workspace.name || "")
      if (workspace.monitor === root.monitor && name.indexOf("special:") !== 0)
        result.push(workspace)
    }

    // Desktop is the stable home workspace created by macos-fullscreen.lua.
    // Keep it first while retaining Hyprland's order for dynamic workspaces.
    result.sort(function(left, right) {
      var leftName = String(left.name || "")
      var rightName = String(right.name || "")
      if (leftName === "Desktop") return -1
      if (rightName === "Desktop") return 1
      return 0
    })
    return result
  }

  readonly property var entries: root.workspacesForMonitor()

  function quoteLua(value) {
    return "\"" + String(value)
      .replace(/\\/g, "\\\\")
      .replace(/\"/g, "\\\"")
      .replace(/\n/g, "\\n")
      .replace(/\r/g, "\\r")
      + "\""
  }

  function focusWorkspace(name) {
    if (!root.monitor || !name) return

    Hyprland.dispatch("function() "
      + "hl.dispatch(hl.dsp.focus({ monitor = " + root.quoteLua(root.monitor.name) + " })); "
      + "hl.dispatch(hl.dsp.focus({ workspace = " + root.quoteLua("name:" + name) + " })); "
      + "end")
  }

  function cycle(step) {
    var values = root.entries
    if (values.length < 2) return

    var index = 0
    for (var i = 0; i < values.length; i++) {
      if (String(values[i].name) === root.activeWorkspaceName) {
        index = i
        break
      }
    }

    var next = ((index + step) % values.length + values.length) % values.length
    root.focusWorkspace(String(values[next].name))
  }

  function handleWheel(delta) {
    // This mouse reports roughly 60 units per physical wheel movement instead
    // of Qt's conventional 120. A smaller threshold keeps one movement equal
    // to one workspace while still accumulating fine touchpad deltas.
    if (delta === 0) return
    if (root.wheelAccumulator * delta < 0) root.wheelAccumulator = 0
    root.wheelAccumulator += Math.max(-120, Math.min(120, delta))
    if (Math.abs(root.wheelAccumulator) < 40) return

    var direction = root.wheelAccumulator > 0 ? -1 : 1
    root.wheelAccumulator = 0
    root.cycle(direction)
  }

  visible: root.entries.length > 0
  implicitWidth: indicators.implicitWidth + root.horizontalPadding * 2
  implicitHeight: root.barSize

  RowLayout {
    id: indicators
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -Style.spaceReal(1)
    spacing: root.indicatorSpacing

    Repeater {
      model: root.entries

      WidgetButton {
        id: indicator
        required property var modelData

        readonly property bool focused:
          String(modelData.name) === root.activeWorkspaceName

        bar: root.bar
        labelVisible: false
        hasVisualContent: true
        horizontalMargin: 0
        verticalPadding: 0
        fixedWidth: indicator.focused ? root.activeWidth : root.dotSize
        fixedHeight: root.barSize
        tooltipText: String(modelData.name)

        Layout.preferredWidth: fixedWidth
        Layout.preferredHeight: fixedHeight

        onPressed: function(button) {
          if (button === Qt.LeftButton) root.focusWorkspace(String(modelData.name))
          else if (button === Qt.RightButton && root.bar && typeof root.bar.toggleRaised === "function")
            root.bar.toggleRaised()
        }
        onWheelMoved: function(delta) { root.handleWheel(delta) }

        Rectangle {
          anchors.centerIn: parent
          width: indicator.focused ? root.activeWidth : root.dotSize
          height: indicator.focused ? root.activeHeight : root.dotSize
          radius: height / 2
          color: root.indicatorColor
          opacity: indicator.focused ? 0.92 : 0.46

          Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
          }
          Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }
        }

        Behavior on fixedWidth {
          NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
      }
    }
  }

  // Covers the gaps between the dots as well, so the whole indicator is one
  // continuous scroll target without stealing any mouse button presses.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function(wheel) {
      root.handleWheel(wheel.angleDelta.y !== 0
        ? wheel.angleDelta.y : wheel.angleDelta.x)
    }
  }
}
