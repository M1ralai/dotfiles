import AppKit
import CoreImage
import CryptoKit
import ImageIO
import Carbon
import Darwin

let fm = FileManager.default
let home = fm.homeDirectoryForCurrentUser
let env = ProcessInfo.processInfo.environment
let root = URL(fileURLWithPath: env["IW_ROOT"] ?? home.appendingPathComponent(".config/invisible-workspace").path)
let cache = URL(fileURLWithPath: env["IW_CACHE"] ?? home.appendingPathComponent("Library/Caches/invisible-workspace").path)
let ghostty = "/Applications/Ghostty.app/Contents/MacOS/ghostty"
struct Failure: Error, CustomStringConvertible { let description: String; init(_ text: String) { description = text } }
func ensure(_ url: URL) throws { try fm.createDirectory(at: url, withIntermediateDirectories: true) }
func write(_ text: String, _ url: URL) throws { try Data(text.utf8).write(to: url, options: .atomic) }
func digest(_ text: String) -> String { SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined() }
func json(_ value: [String: Any]) throws -> String { String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self) + "\n" }
let defaults: [String: String] = ["blur":"6", "dimming":"0.70", "saturation":"0.85", "brightness":"0", "opacity":"0.80", "max_dimension":"2560", "cursor":"off", "source":""]
let order = ["blur", "dimming", "saturation", "brightness", "opacity", "max_dimension", "cursor", "source"]
struct Settings {
    var values = defaults
    init() throws {
        let file = root.appendingPathComponent("config.toml")
        if fm.fileExists(atPath: file.path) {
            let contents = try String(contentsOf: file, encoding: .utf8)
            var seen = Set<String>()
            for raw in contents.components(separatedBy: .newlines) {
                let line = raw.trimmingCharacters(in: .whitespaces)
                if line.isEmpty || line.hasPrefix("#") { continue }
                let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count == 2, defaults[parts[0]] != nil, seen.insert(parts[0]).inserted else { throw Failure("Invalid or duplicate setting: \(line)") }
                var value = parts[1]
                if value.hasPrefix("\"") && value.hasSuffix("\"") { value = String(value.dropFirst().dropLast()) }
                values[parts[0]] = value
            }
        }
        try validate()
    }
    func number(_ key: String) -> Double { Double(values[key]!)! }
    func validate() throws {
        let ranges: [String: ClosedRange<Double>] = ["blur":0...40,"dimming":0...0.95,"saturation":0...2,"brightness":(-0.5)...0.5,"opacity":0...1,"max_dimension":640...4096]
        for (key, range) in ranges {
            guard let n = Double(values[key]!), n.isFinite, range.contains(n) else { throw Failure("\(key) must be finite and in \(range)") }
        }
        guard ["on", "off"].contains(values["cursor"]!) else { throw Failure("cursor must be on or off") }
        let source = values["source"]!
        guard source.isEmpty || source.hasPrefix("/") else { throw Failure("source must be an absolute image path, or empty for automatic detection") }
        guard !source.contains("\n"), !source.contains("\""), !source.contains("\\") else { throw Failure("source cannot contain quotes, backslashes, or newlines") }
    }
    var text: String {
        "# Invisible Workspace: use scripts/sync-wallpaper set KEY VALUE\n# blur: output pixels; dimming: black blend; brightness: -0.5...0.5\n# opacity: image opacity INSIDE an opaque terminal, not window transparency\n# cursor on is experimental and runs Ghostty's continuous focused render loop\n# source empty follows macOS; only flat scalar TOML settings are supported\n" + order.map { "\($0) = " + (["cursor","source"].contains($0) ? "\"\(values[$0]!)\"" : values[$0]!) }.joined(separator: "\n") + "\n"
    }
}
func displayID(_ screen: NSScreen) -> CGDirectDisplayID { (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? CGMainDisplayID() }
func targetScreen() throws -> (NSScreen, String) {
    let screens = NSScreen.screens
    guard let main = screens.first(where: { displayID($0) == CGMainDisplayID() }) ?? screens.first else { throw Failure("No active display; retaining last good wallpaper") }
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")
    let pids = Set(apps.map { $0.processIdentifier })
    if let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String:Any]] {
        for w in windows {
            guard let pid = w[kCGWindowOwnerPID as String] as? Int32, pids.contains(pid),
                  (w[kCGWindowLayer as String] as? Int) == 0,
                  let b = w[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: b), rect.width > 100, rect.height > 100 else { continue }
            if let selected = screens.max(by: {
                let a = CGDisplayBounds(displayID($0)).intersection(rect), b = CGDisplayBounds(displayID($1)).intersection(rect)
                return (a.isNull ? 0 : a.width*a.height) < (b.isNull ? 0 : b.width*b.height)
            }), CGDisplayBounds(displayID(selected)).intersects(rect) { return (selected, "frontmost visible Ghostty window") }
        }
    }
    return (main, "main display fallback; no visible Ghostty window bounds")
}
func inspection() throws -> [String:Any] {
    let (target, reason) = try targetScreen()
    return ["selected_display": displayID(target), "selection": reason, "screen_capture_authorized": CGPreflightScreenCaptureAccess(), "screens": NSScreen.screens.map { s -> [String:Any] in
        let id = displayID(s)
        return ["id":id,"name":s.localizedName,"width":CGDisplayPixelsWide(id),"height":CGDisplayPixelsHigh(id),"wallpaper":NSWorkspace.shared.desktopImageURL(for:s)?.path ?? "unavailable", "desktop_options":String(describing:NSWorkspace.shared.desktopImageOptions(for:s) ?? [:])]
    }]
}
func render(_ source: URL, to output: URL, width: Int, height: Int, settings: Settings) throws {
    guard ["jpg","jpeg","png","heic","heif","tif","tiff","bmp"].contains(source.pathExtension.lowercased()),
          var image = CIImage(contentsOf: source, options: [.applyOrientationProperty:true]),
          image.extent.width > 0, image.extent.height > 0 else { throw Failure("Unsupported or unreadable wallpaper: \(source.path). Keeping last good image; videos/Apple animated wallpapers are not supported.") }
    let e = image.extent
    image = image.transformed(by: CGAffineTransform(translationX: -e.minX, y: -e.minY))
    let scale = max(Double(width)/e.width, Double(height)/e.height)
    image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    image = image.transformed(by: CGAffineTransform(translationX: (Double(width)-image.extent.width)/2, y: (Double(height)-image.extent.height)/2))
    let rect = CGRect(x:0,y:0,width:width,height:height)
    image = image.cropped(to:rect)
    if settings.number("blur") > 0 { image = image.clampedToExtent().applyingFilter("CIGaussianBlur", parameters:[kCIInputRadiusKey:settings.number("blur")]).cropped(to:rect) }
    image = image.applyingFilter("CIColorControls", parameters:[kCIInputSaturationKey:settings.number("saturation"),kCIInputBrightnessKey:settings.number("brightness"),kCIInputContrastKey:1])
    // A uniform black blend; no regional masks, terminal rasterization or source edits.
    let factor = 1 - settings.number("dimming")
    image = image.applyingFilter("CIColorMatrix", parameters:["inputRVector":CIVector(x:factor,y:0,z:0,w:0),"inputGVector":CIVector(x:0,y:factor,z:0,w:0),"inputBVector":CIVector(x:0,y:0,z:factor,w:0)])
    let space = CGColorSpace(name:CGColorSpace.sRGB)!
    let context = CIContext(options:[.workingColorSpace:space,.outputColorSpace:space])
    guard let png = context.pngRepresentation(of:image, format:.RGBA8, colorSpace:space) else { throw Failure("Core Image could not encode wallpaper") }
    try png.write(to:output,options:.atomic)
}
func generated(_ image: URL, _ settings: Settings) throws -> String {
    guard !image.path.contains("\n"), !image.path.contains("\"") else { throw Failure("Unsupported cache path characters") }
    let shader = root.appendingPathComponent("shaders/cursor.glsl")
    if settings.values["cursor"] == "on" && !fm.fileExists(atPath:shader.path) { throw Failure("Optional cursor shader is missing") }
    return """
    # Managed by Invisible Workspace. Edit ../config.toml or use scripts/sync-wallpaper.
    theme = Rose Pine
    background = #10161d
    foreground = #9fbac8
    background-opacity = 1
    background-blur = false
    background-image = "\(image.path)"
    background-image-fit = cover
    background-image-position = center
    background-image-repeat = false
    background-image-opacity = \(settings.values["opacity"]!)
    mouse-hide-while-typing = true
    window-padding-x = 8
    window-padding-y = 8
    window-decoration = true
    macos-titlebar-style = hidden
    resize-overlay = never
    custom-shader =
    \(settings.values["cursor"] == "on" ? "custom-shader = \"\(shader.path)\"" : "# Cursor animation disabled: no continuous idle render loop.")
    custom-shader-animation = \(settings.values["cursor"] == "on" ? "true" : "false")
    """ + "\n"
}
func validateGhostty(_ file: URL) throws {
    let process = Process(), pipe = Pipe()
    process.executableURL = URL(fileURLWithPath:ghostty)
    process.arguments = ["+validate-config", "--config-file=\(file.path)"]
    process.standardOutput = pipe; process.standardError = pipe
    try process.run()
    let output = String(decoding:pipe.fileHandleForReading.readDataToEndOfFile(),as:UTF8.self)
    process.waitUntilExit()
    guard process.terminationStatus == 0, output.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { throw Failure("Ghostty rejected generated configuration: \(output)") }
}
func reload() -> String {
    if env["IW_NO_RELOAD"] == "1" { return "disabled for isolated test" }
    guard !NSRunningApplication.runningApplications(withBundleIdentifier:"com.mitchellh.ghostty").isEmpty else { return "Ghostty not running; next launch reads configuration" }
    var target = AEAddressDesc()
    let id = "com.mitchellh.ghostty"
    let create = id.withCString { AECreateDesc(DescType(typeApplicationBundleID),$0,id.utf8.count,&target) }
    guard create == noErr else { return "Manual reload required: Apple Event descriptor unavailable" }
    defer { AEDisposeDesc(&target) }
    let permission = AEDeterminePermissionToAutomateTarget(&target,AEEventClass(typeWildCard),AEEventID(typeWildCard),false)
    guard permission == noErr else { return "Manual reload required (Command-Shift-comma); Automation not authorized (\(permission))" }
    var error: NSDictionary?
    let result = NSAppleScript(source:"""
    with timeout of 5 seconds
        tell application id "com.mitchellh.ghostty"
            if (count of terminals) is 0 then return false
            return perform action "reload_config" on first terminal
        end tell
    end timeout
    """)?.executeAndReturnError(&error)
    if let error = error { return "Manual reload required: \(error)" }
    return result?.booleanValue == true ? "Ghostty reload_config action accepted; visual refresh not independently verified" : "No terminal accepted reload; use Command-Shift-comma"
}
func refresh(_ settings: Settings) throws {
    let (screen, reason) = try targetScreen()
    let source: URL
    if settings.values["source"]!.isEmpty {
        guard let url = NSWorkspace.shared.desktopImageURL(for:screen), url.isFileURL else { throw Failure("macOS did not provide a local wallpaper image; retaining last good output") }
        source = url
    } else { source = URL(fileURLWithPath:settings.values["source"]!) }
    guard fm.isReadableFile(atPath:source.path) else { throw Failure("Wallpaper is missing or inaccessible: \(source.path). Last good output retained.") }
    let attr = try fm.attributesOfItem(atPath:source.path)
    let id = displayID(screen)
    let mode = CGDisplayCopyDisplayMode(id)
    let w = mode?.pixelWidth ?? Int(screen.frame.width * screen.backingScaleFactor)
    let h = mode?.pixelHeight ?? Int(screen.frame.height * screen.backingScaleFactor)
    guard w > 0, h > 0 else { throw Failure("Display dimensions unavailable") }
    let scale = min(1,settings.number("max_dimension")/Double(max(w,h)))
    let width = Int((Double(w)*scale).rounded()), height = Int((Double(h)*scale).rounded())
    let renderKeys = ["blur","dimming","saturation","brightness"]
    let stamp = "v1|\(source.path)|\(attr[.size] ?? 0)|\((attr[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0)|\(width)x\(height)|" + renderKeys.map { settings.values[$0]! }.joined(separator:"|")
    let image = cache.appendingPathComponent("processed/\(digest(stamp)).png")
    let conf = root.appendingPathComponent("ghostty/generated.conf")
    let text = try generated(image,settings)
    let previous = try? String(contentsOf:conf,encoding:.utf8)
    let needed = !fm.fileExists(atPath:image.path)
    if needed { try render(source,to:image,width:width,height:height,settings:settings) }
    if previous == text && !needed { print("Unchanged; cached wallpaper retained."); return }
    let candidate = root.appendingPathComponent("ghostty/.candidate.conf")
    defer { try? fm.removeItem(at:candidate) }
    try write(text,candidate)
    try validateGhostty(candidate)
    try write(text,conf)
    let reloadStatus = reload()
    var state: [String:Any] = ["source":source.path,"image":image.path,"width":width,"height":height,"display_id":id,"screen_selection":reason,"reload":reloadStatus,"updated":ISO8601DateFormatter().string(from:Date()),"generated":needed]
    if let src = CGImageSourceCreateWithURL(source as CFURL,nil), CGImageSourceGetCount(src) > 1 { state["limitation"] = "Multi-frame/dynamic source: static decoded frame only; time-of-day appearance is not verified." }
    try write(try json(state),root.appendingPathComponent("state.json"))
    print(try json(state))
    // Keep a small set for rollback and existing renderers. Never touch original images.
    let files = (try? fm.contentsOfDirectory(at:cache.appendingPathComponent("processed"),includingPropertiesForKeys:[.contentModificationDateKey])) ?? []
    let owned = files.filter { $0.lastPathComponent.range(of:"^[0-9a-f]{64}\\.png$",options:.regularExpression) != nil }.sorted { ((try? $0.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
    for old in owned.dropFirst(8) where old != image { try? fm.removeItem(at:old) }
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    let action = args.first ?? "refresh"
    if action == "inspect" { print(try json(inspection())); exit(0) }
    if action == "help" || action == "--help" {
        print("sync-wallpaper refresh | inspect | status | reload | set KEY VALUE\nSettings: blur 0...40, dimming 0...0.95, saturation 0...2, brightness -0.5...0.5, opacity 0...1, max_dimension 640...4096, cursor on|off, source /absolute/image (empty = macOS).\nRollback: ~/.config/invisible-workspace/scripts/rollback")
        exit(0)
    }
    if action == "status" { print(try String(contentsOf:root.appendingPathComponent("state.json"),encoding:.utf8)); exit(0) }
    if action == "reload" { print(reload()); exit(0) }
    guard action == "refresh" || action == "set" else { throw Failure("Unknown action; use --help") }
    try ensure(root); try ensure(root.appendingPathComponent("ghostty")); try ensure(cache.appendingPathComponent("processed"))
    let lock = open(root.appendingPathComponent(".sync.lock").path,O_CREAT|O_RDWR,S_IRUSR|S_IWUSR)
    guard lock >= 0 else { throw Failure("Cannot open synchronization lock") }
    defer { close(lock) }
    guard flock(lock,LOCK_EX|LOCK_NB) == 0 else { throw Failure("Another wallpaper sync is running; retry shortly") }
    var settings = try Settings()
    if action == "set" {
        guard args.count == 3, defaults[args[1]] != nil else { throw Failure("Usage: sync-wallpaper set KEY VALUE; see --help") }
        settings.values[args[1]] = args[2]; try settings.validate()
    }
    try refresh(settings)
    let path = root.appendingPathComponent("config.toml")
    if action == "set" || !fm.fileExists(atPath:path.path) { try write(settings.text,path) }
} catch { fputs("Invisible Workspace: \(error)\n",stderr); exit(1) }
