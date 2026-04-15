//
//  ClipboardWatcher.swift
//  clipboard-manager
//
//  Created by Luca Nardelli on 10/04/2019.
//  Copyright © 2019 Luca Nardelli. All rights reserved.
//
//  Modifications by David Zellhöfer (2026):
//  * added support for application detection based on bundle information in order to react differently to each app causing a clipboard event
//  * watcher can now detect whether the clipboard has been changed by the app or something else in order to monitor usage properly
//  * added documentation
//

import Foundation
import AppKit

final class ClipboardService {
    
    // allows to discover if the clipboard has been altered by the app itself
    static var selfTriggerClipboardChange: Bool = false
    
    static func watch() {
        let pasteboard = NSPasteboard.general;
        var lastChangeCount = pasteboard.changeCount;
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            let actualChangeCount = pasteboard.changeCount
            if actualChangeCount != lastChangeCount {
                //print("[DEBUG] ClipboardServie: change detected")
                lastChangeCount = actualChangeCount
                if let value = pasteboard.string(forType: .string) {
                    if !selfTriggerClipboardChange{
                        // if the clipboard has been altered by the app itself, we do not have to add an item;
                        // otherwise it would reset the hits counter
                        PersistenceService.addItem(value)
                        
                        
                    }
                    PersistenceService.filterSortItems()
                    // reset the trigger when done updating
                    selfTriggerClipboardChange = false
                    
                    // daz: detect which app pasted to the clipboard
                    let app = NSWorkspace.shared.frontmostApplication
                    let bundleID=app?.bundleIdentifier ?? "unbekannt"
                    print("[DEBUG] Last active app: \(bundleID)")
                    
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                        let bundle = Bundle(url: url)
                        let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                               ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        print(name ?? "unbekannt")
                    }
                }
            }
        })
    }
    
    /// <#Description#>
    /// - Parameter value: <#value description#>
    static func pasteItem(_ value: String) {
        /*guard isAccessibilityEnabled(isPrompt: false) else {
            showAccessibilityAuthenticationAlert()
            return
        }*/
        selfTriggerClipboardChange=true
        let pasteboard = NSPasteboard.general;
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        NSApplication.shared.hide(nil)
          
        let event1 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true); // cmd-v down
        event1?.flags = CGEventFlags.maskCommand;
        event1?.post(tap: CGEventTapLocation.cghidEventTap);
        
        let event2 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) // cmd-v up
        event2?.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    static func isAccessibilityEnabled(isPrompt: Bool) -> Bool {
        let checkOptionPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [checkOptionPromptKey: isPrompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    static func showAccessibilityAuthenticationAlert() {
        let alert = NSAlert()
        alert.messageText = "Accesibility is required to paste"
        alert.informativeText = "Accesibility is required to paste"
        alert.addButton(withTitle: "Allow")
        NSApp.activate(ignoringOtherApps: true)

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            guard !openAccessibilitySettingWindow() else { return }
        }
        func openAccessibilitySettingWindow() -> Bool {
           guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return false }
           return NSWorkspace.shared.open(url)
       }
    }
}
