import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Ignore SIGPIPE so the app doesn't crash when adb spawns its background
    // daemon and the pipe between them is closed prematurely.
    signal(SIGPIPE, SIG_IGN)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }
}
