import Foundation

enum AutoStartManager {
    private static let launchAgentLabel = "com.easyclip.launcher"
    private static var launchAgentsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }
    private static var plistURL: URL {
        launchAgentsDir.appendingPathComponent("\(launchAgentLabel).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try register()
        } else {
            try unregister()
        }
    }

    private static func register() throws {
        try FileManager.default.createDirectory(
            at: launchAgentsDir,
            withIntermediateDirectories: true
        )

        let execPath = Bundle.main.bundlePath + "/Contents/MacOS/" + (Bundle.main.executableURL?.lastPathComponent ?? "EasyClip")

        let plistXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """
        try plistXML.write(to: plistURL, atomically: true, encoding: .utf8)

        // Load now
        let load = Process()
        load.launchPath = "/bin/launchctl"
        load.arguments = ["load", plistURL.path]
        load.launch()
        load.waitUntilExit()

        // Start now
        let start = Process()
        start.launchPath = "/bin/launchctl"
        start.arguments = ["start", launchAgentLabel]
        start.launch()
    }

    private static func unregister() throws {
        // Stop and unload
        let stop = Process()
        stop.launchPath = "/bin/launchctl"
        stop.arguments = ["stop", launchAgentLabel]
        stop.launch()
        stop.waitUntilExit()

        let unload = Process()
        unload.launchPath = "/bin/launchctl"
        unload.arguments = ["unload", plistURL.path]
        unload.launch()
        unload.waitUntilExit()

        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }
}
