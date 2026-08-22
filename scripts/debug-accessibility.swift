#!/usr/bin/env swift
import ApplicationServices
import Foundation

print("=== GitPalette accessibility debug ===")
print("time:", Date())
print("AXIsProcessTrusted:", AXIsProcessTrusted())
let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
print("AXIsProcessTrustedWithOptions(prompt:false):", AXIsProcessTrustedWithOptions(options))

let identities = shell("security find-identity -v -p codesigning")
print("\n=== codesigning identities ===")
print(identities.isEmpty ? "(none)" : identities)

print("\n=== GitPalette processes ===")
print(shell("pgrep -fl GitPalette || true"))

print("\n=== verdict ===")
if identities.contains("0 valid identities found") || !identities.contains("Apple Development") {
    print("No Apple Development identity. Xcode signs GitPalette-Debug adhoc.")
    print("Adhoc + Accessibility: System Settings toggle often does NOT make AXIsProcessTrusted() true.")
    print("tccutil reset Accessibility <bundle-id> commonly fails in this state.")
    print("Carbon global hotkeys (KeyboardShortcuts) do not need Accessibility.")
    print("The app must not block the launcher on AXIsProcessTrusted().")
} else {
    print("A development identity exists. Prefer non-adhoc Debug signing so TCC can stick.")
}

func shell(_ command: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-lc", command]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try? process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
