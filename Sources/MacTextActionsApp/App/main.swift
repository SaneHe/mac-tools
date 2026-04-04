import AppKit
import SwiftUI

private var appDelegate: AppDelegate?

let app = NSApplication.shared
appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
