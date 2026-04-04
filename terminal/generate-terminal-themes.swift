#!/usr/bin/env swift

// generate-terminal-themes.swift
// Generates macOS Terminal.app .terminal profile files for AmberPhosphor theme
// PC-12 amber phosphor CRT color palette
// Run: swift terminal/generate-terminal-themes.swift

import AppKit
import Foundation

// MARK: - Color Palette (PC-12 Amber Phosphor)

struct ThemeColors {
    let name: String
    let background: String
    let foreground: String
    let boldText: String
    let cursor: String
    let selectionR: CGFloat
    let selectionG: CGFloat
    let selectionB: CGFloat
    let selectionA: CGFloat
    let ansiBlack: String
    let ansiRed: String
    let ansiGreen: String
    let ansiYellow: String
    let ansiBlue: String
    let ansiMagenta: String
    let ansiCyan: String
    let ansiWhite: String
    let ansiBrightBlack: String
    let ansiBrightRed: String
    let ansiBrightGreen: String
    let ansiBrightYellow: String
    let ansiBrightBlue: String
    let ansiBrightMagenta: String
    let ansiBrightCyan: String
    let ansiBrightWhite: String
}

// Pure monochrome amber — all colors are brightness variations of PC-12 amber
let monochromeTheme = ThemeColors(
    name: "AmberPhosphor",
    background: "#1A1000",
    foreground: "#FFB000",
    boldText: "#FFD066",
    cursor: "#FFB000",
    selectionR: 1.0, selectionG: 0.6875, selectionB: 0.0, selectionA: 0.25,
    ansiBlack: "#332200",
    ansiRed: "#CC8800",
    ansiGreen: "#B38000",
    ansiYellow: "#FFB000",
    ansiBlue: "#997300",
    ansiMagenta: "#D99A00",
    ansiCyan: "#E6A600",
    ansiWhite: "#FFD066",
    ansiBrightBlack: "#665500",
    ansiBrightRed: "#FFCC44",
    ansiBrightGreen: "#FFD066",
    ansiBrightYellow: "#FFE099",
    ansiBrightBlue: "#CC9933",
    ansiBrightMagenta: "#FFD066",
    ansiBrightCyan: "#FFCC44",
    ansiBrightWhite: "#FFE099"
)

// Amber-tinted ANSI — warm-spectrum chromatic variants for distinguishable colors
let ansiTheme = ThemeColors(
    name: "AmberPhosphor ANSI",
    background: "#1A1000",
    foreground: "#FFB000",
    boldText: "#FFD066",
    cursor: "#FFB000",
    selectionR: 1.0, selectionG: 0.6875, selectionB: 0.0, selectionA: 0.25,
    ansiBlack: "#332200",
    ansiRed: "#FF6622",
    ansiGreen: "#88AA00",
    ansiYellow: "#FFB000",
    ansiBlue: "#CC8844",
    ansiMagenta: "#DD7744",
    ansiCyan: "#AAAA33",
    ansiWhite: "#FFD066",
    ansiBrightBlack: "#665500",
    ansiBrightRed: "#FF8844",
    ansiBrightGreen: "#AACC22",
    ansiBrightYellow: "#FFD066",
    ansiBrightBlue: "#DDAA66",
    ansiBrightMagenta: "#FF9966",
    ansiBrightCyan: "#CCCC55",
    ansiBrightWhite: "#FFE099"
)

// MARK: - Hex to NSColor

func hexToNSColor(_ hex: String) -> NSColor {
    let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let scanner = Scanner(string: h)
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

// MARK: - Archive NSColor to base64

func archiveColor(_ color: NSColor) -> String {
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: color,
        requiringSecureCoding: true
    )
    return data.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])
}

func archiveColorFromHex(_ hex: String) -> String {
    return archiveColor(hexToNSColor(hex))
}

// MARK: - Archive font (Menlo 14pt for retro CRT aesthetic)

func archiveFont() -> String {
    let font = NSFont(name: "Menlo-Regular", size: 14)
        ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: font,
        requiringSecureCoding: true
    )
    return data.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])
}

// MARK: - Generate .terminal plist XML

func generateTerminalPlist(_ theme: ThemeColors) -> String {
    let selectionColor = NSColor(
        srgbRed: theme.selectionR,
        green: theme.selectionG,
        blue: theme.selectionB,
        alpha: theme.selectionA
    )

    let colors: [(String, String)] = [
        ("BackgroundColor", archiveColorFromHex(theme.background)),
        ("TextColor", archiveColorFromHex(theme.foreground)),
        ("TextBoldColor", archiveColorFromHex(theme.boldText)),
        ("CursorColor", archiveColorFromHex(theme.cursor)),
        ("CursorTextColor", archiveColorFromHex(theme.background)),
        ("SelectionColor", archiveColor(selectionColor)),
        ("ANSIBlackColor", archiveColorFromHex(theme.ansiBlack)),
        ("ANSIRedColor", archiveColorFromHex(theme.ansiRed)),
        ("ANSIGreenColor", archiveColorFromHex(theme.ansiGreen)),
        ("ANSIYellowColor", archiveColorFromHex(theme.ansiYellow)),
        ("ANSIBlueColor", archiveColorFromHex(theme.ansiBlue)),
        ("ANSIMagentaColor", archiveColorFromHex(theme.ansiMagenta)),
        ("ANSICyanColor", archiveColorFromHex(theme.ansiCyan)),
        ("ANSIWhiteColor", archiveColorFromHex(theme.ansiWhite)),
        ("ANSIBrightBlackColor", archiveColorFromHex(theme.ansiBrightBlack)),
        ("ANSIBrightRedColor", archiveColorFromHex(theme.ansiBrightRed)),
        ("ANSIBrightGreenColor", archiveColorFromHex(theme.ansiBrightGreen)),
        ("ANSIBrightYellowColor", archiveColorFromHex(theme.ansiBrightYellow)),
        ("ANSIBrightBlueColor", archiveColorFromHex(theme.ansiBrightBlue)),
        ("ANSIBrightMagentaColor", archiveColorFromHex(theme.ansiBrightMagenta)),
        ("ANSIBrightCyanColor", archiveColorFromHex(theme.ansiBrightCyan)),
        ("ANSIBrightWhiteColor", archiveColorFromHex(theme.ansiBrightWhite)),
    ]

    let fontData = archiveFont()

    var xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    \t<key>name</key>
    \t<string>\(theme.name)</string>
    \t<key>type</key>
    \t<string>Window Settings</string>
    \t<key>ProfileCurrentVersion</key>
    \t<real>2.08</real>

    """

    for (key, value) in colors {
        xml += "\t<key>\(key)</key>\n"
        xml += "\t<data>\n\(value)\n\t</data>\n"
    }

    xml += """
    \t<key>Font</key>
    \t<data>
    \(fontData)
    \t</data>
    \t<key>FontAntialias</key>
    \t<true/>
    \t<key>FontWidthSpacing</key>
    \t<real>1.004032258064516</real>
    \t<key>UseBoldFonts</key>
    \t<true/>
    \t<key>DisableANSIColor</key>
    \t<false/>
    \t<key>UseBrightBold</key>
    \t<true/>
    \t<key>columnCount</key>
    \t<integer>80</integer>
    \t<key>rowCount</key>
    \t<integer>24</integer>
    \t<key>ShouldLimitScrollback</key>
    \t<integer>0</integer>
    \t<key>ShowRepresentedURLInTitle</key>
    \t<true/>
    \t<key>ShowRepresentedURLPathInTitle</key>
    \t<true/>
    \t<key>ShowActiveProcessInTitle</key>
    \t<true/>
    \t<key>ShowWindowSettingsNameInTitle</key>
    \t<false/>
    </dict>
    </plist>
    """

    return xml
}

// MARK: - Main

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDir = scriptURL.deletingLastPathComponent()

let outputDir: URL
if scriptDir.lastPathComponent == "terminal" {
    outputDir = scriptDir
} else {
    outputDir = scriptDir.appendingPathComponent("terminal")
}

let themes: [(ThemeColors, String)] = [
    (monochromeTheme, "AmberPhosphor.terminal"),
    (ansiTheme, "AmberPhosphor-ANSI.terminal"),
]

for (theme, filename) in themes {
    let plist = generateTerminalPlist(theme)
    let outputPath = outputDir.appendingPathComponent(filename)
    try! plist.write(to: outputPath, atomically: true, encoding: .utf8)
    print("Generated: \(outputPath.path)")
}

print("Done. Import into Terminal.app via Settings > Profiles > Import.")
