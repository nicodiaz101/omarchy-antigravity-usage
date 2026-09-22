import QtQuick
import Quickshell
import Quickshell.Io

// Headless collector for the stock omarchy.agents panel.
// Writes ~/.local/state/omarchy/agents/usage/antigravity.json; the built-in
// AI button already watches that directory and draws whatever appears.
Item {
  id: root

  property var manifest: null
  property var shell: null

  readonly property string collector: decodeURIComponent(String(Qt.resolvedUrl("collect.py")).replace(/^file:\/\//, ""))
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string claudeRecord: stateHome + "/omarchy/agents/usage/claude.json"

  function collect(force) {
    if (collector === "" || collectProcess.running) return
    var cmd = ["python3", collector, "--write"]
    if (force === true) cmd.push("--force")
    collectProcess.command = cmd
    collectProcess.running = true
  }

  Component.onCompleted: root.collect(false)

  Timer {
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.collect(false)
  }

  // Stock panel refresh rewrites claude.json. Use that as a cue so Antigravity
  // updates when the user hits r, not only on this timer.
  FileView {
    path: root.claudeRecord
    watchChanges: true
    printErrors: false
    onFileChanged: root.collect(false)
  }

  Process {
    id: collectProcess
    running: false
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("antigravity-usage", text.trim())
    }
  }
}
