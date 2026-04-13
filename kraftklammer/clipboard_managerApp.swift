//
//  clipboard_managerApp.swift
//  clipboard-manager
//
//  Created by Luca Nardelli on 27/03/25.
//
//  Modifications by David Zellhöfer (2026):
//  * preparations for localization
//  * added documentation
//  * prepared menu for further development and made it consistent with OS standards
//  * added history clearing
//

import SwiftUI

@main
struct clipboard_managerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {}
    }
    
    init() {
            UserDefaults.standard.register(defaults: [
                "maxHistoryEntries": 50
            ])
        }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var hostingController: NSHostingController<ContentView>!
    var statusItem: NSStatusItem!
    var hotkeyHandler: HotkeySettingsHandler!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
        hostingController = NSHostingController(rootView: contentView)

        panel = ClipWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 550),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingController.view
        
        //TODO: Ensure that the needed permission are granted to the app
        // "Accessibility" (aka "Bedienungshilfen)
        //IOHIDRequestAccess(kIOHIDRequestTypePostEvent)
        

        
        
        // daz
        //Window("What's New", id: "whats-new") {
        //    Text("New in this version…")
        //}
        // daz
        

        setupStatusBarItem()
        hotkeyHandler = HotkeySettingsHandler(panel: panel)
        HotKeysService.register() { self.show() }
        DBService.initialize()
        ClipboardService.watch()
    }
    
    
    
    /*
     *  Displays the clipboard item list
     */
    @objc func show() {
        for screen in NSScreen.screens {
           let mouseX = NSEvent.mouseLocation.x;
           let mouseY = NSEvent.mouseLocation.y;
           if screen.frame.minX < mouseX && screen.frame.maxX > mouseX
               && screen.frame.minY < mouseY && screen.frame.maxY > mouseY {
               let centerX = screen.frame.minX + (screen.frame.maxX - screen.frame.minX) / 2 - 150
               let centerY = screen.frame.minY + (screen.frame.maxY - screen.frame.minY) / 2 + 200
               panel.setFrameTopLeftPoint(NSPoint(x: centerX, y: centerY))
           }
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            panel.animator().alphaValue = 1.0
        })
    }

    @objc func showHotkeySettings() {
        hotkeyHandler.showHotkeySettings()
    }
    
    // deletes all items from history
    @objc func deleteHistory() {
        DBService.deleteAll()
    }

    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            // set icon for status bar
            // systenSymbolName values can only be determined by using Apple's SF Symbols app that can be downoaded from https://developer.apple.com/sf-symbols/
            // we will use a different status bar icon if we are running in debug mode to facilitate visual discrimination
            #if DEBUG
            button.image = NSImage(systemSymbolName: "heart.text.clipboard.fill", accessibilityDescription: nil)
            #else
            // No debugging information in release build
            button.image = NSImage(named: "StatusBarIcon_Placeholder")
            #endif
        }
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: String(localized:"Show items..."), action: #selector(show), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: String(localized:"Delete history..."), action:#selector(deleteHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: String(localized:"Settings..."), action: #selector(showHotkeySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: String(localized:"Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
}
