//
//  SettingsView.swift
//  clipboard-manager
//
//  Created by Luca Nardelli on 27/03/25.
//
//  Modifications by David Zellhöfer (2026):
//  * preparations for localization
//  * added documentation
//  * added licensing information
//  * made layout more consistent
//  * added tabbed view
//

import SwiftUI
import Carbon

struct HotkeyRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onKeyRecorded: (UInt32, UInt32) -> Void
    
    class Coordinator: NSObject {
        var parent: HotkeyRecorder
        var monitor: Any?
        
        init(_ parent: HotkeyRecorder) {
            self.parent = parent
        }
        
        func startRecording() {
            if self.monitor != nil {
                return
            }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                self?.handleKeyEvent(event)
                return nil
            }
        }
        
        func stopRecording() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
        
        func handleKeyEvent(_ event: NSEvent) {
            let keyCode = UInt32(event.keyCode)
            var modifiers: UInt32 = 0
            
            if event.modifierFlags.contains(.command) {
                modifiers |= UInt32(cmdKey)
            }
            if event.modifierFlags.contains(.option) {
                modifiers |= UInt32(optionKey)
            }
            if event.modifierFlags.contains(.control) {
                modifiers |= UInt32(controlKey)
            }
            if event.modifierFlags.contains(.shift) {
                modifiers |= UInt32(shiftKey)
            }
            
            parent.onKeyRecorded(keyCode, modifiers)
            parent.isRecording = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            context.coordinator.startRecording()
        } else {
            context.coordinator.stopRecording()
        }
    }
    
}



// view definition of the settings dialog
struct HotkeySettingsView: View {
    @State private var isRecordingHotkey = false
    @State private var currentHotkey: HotKeyConfiguration
    @State private var showInvalidHotkeyAlert = false
    @State private var showSuccessIndicator = false
    @Environment(\.colorScheme) var colorScheme
    
    // enum to control the displayed tabs
    enum TabsType: Int {
        case settingsTab = 0, advancedTab
    }
    
    @State private var selectedTab: TabsType = .settingsTab
    
    init() {
        _currentHotkey = State(initialValue: SettingsService.shared.hotKeyConfiguration)
    }
    //MARK: Define body
    var body: some View {
        TabView(selection: $selectedTab) {
            //TODO: migrate to separate function for better overview
            Tab("Settings", systemImage: "tray.and.arrow.down.fill",value: .settingsTab){
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 36))
                            .foregroundStyle(.blue)
                        
                        Text("Keyboard Shortcuts")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 16)
                    
                    Divider()
                    
                    // Current hotkey display
                    VStack(spacing: 16) {
                        Text("Current Shortcut")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            
                            Text(currentHotkey.description)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            
                            if showSuccessIndicator {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 24))
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // daz
                            /*
                             Button("Reset to Default") {
                             /*
                              withAnimation {
                              SettingsService.shared.resetHotKeyToDefault()
                              currentHotkey = SettingsService.shared.hotKeyConfiguration
                              HotKeysService.reregister()
                              }
                              */
                             }
                             .foregroundColor(.blue)
                             //.padding(.vertical, 8)
                             .padding(.horizontal, 16)
                             */
                            Button(action: {
                                isRecordingHotkey = true
                            }) {
                                HStack {
                                    Image(systemName: isRecordingHotkey ? "keyboard" : "record.circle")
                                    Text(isRecordingHotkey ? "Listening for key press..." : "Record New Shortcut")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isRecordingHotkey ? Color.orange : Color.blue)
                                        .opacity(isRecordingHotkey ? 0.8 : 1)
                                )
                                .foregroundColor(.white)
                                .animation(.easeOut(duration: 0.2), value: isRecordingHotkey)
                            }
                            .buttonStyle(.plain)
                            .disabled(isRecordingHotkey)
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.spring(response: 0.3), value: showSuccessIndicator)
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        HStack{
                            Spacer()
                            Button("Reset to Default") {
                                withAnimation {
                                    SettingsService.shared.resetHotKeyToDefault()
                                    currentHotkey = SettingsService.shared.hotKeyConfiguration
                                    HotKeysService.reregister()
                                }
                            }
                            .foregroundColor(.blue)
                            //.padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .disabled(isRecordingHotkey)
                        }
                    }
                    //.padding(.horizontal)
                    
                    Spacer()
                    
                    // Tip text
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Tips for Keyboard Shortcuts")
                                .font(.headline)
                        }
                        
                        Text("The shortcut must include at least one modifier key (⌘, ⌥, ⌃, ⇧). Good shortcuts use combinations that don't conflict with system commands.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            Image(systemName: "heart.rectangle.fill")
                                .foregroundColor(.blue)
                            Text("This Software is Open Source")
                                .font(.headline)
                        }
                        Text("This software is available under the MIT license.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Button("See license...") {
                            selectedTab = .advancedTab
                            displayLicenses()
                            withAnimation {
                                // daz: to do
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.darkGray).opacity(0.3) : Color.blue.opacity(0.05))
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                // modified height
                .frame(width: 400, height: 520)
                .background(
                    HotkeyRecorder(isRecording: $isRecordingHotkey) { keyCode, modifiers in
                        handleKeyRecorded(keyCode: keyCode, modifiers: modifiers)
                    }
                )
                .alert("Invalid Shortcut", isPresented: $showInvalidHotkeyAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The keyboard shortcut must include at least one modifier key (⌘, ⌥, ⌃, ⇧)")
                }
            }
            Tab("Advanced", systemImage: "tray.and.arrow.down.fill",value: .advancedTab){
                AdvancedTabView()
            }
        }
        //.tabViewStyle(.sidebarAdaptable)
        
    }
    // view body end
    
    /*
     * Contents of the advanced tab view
     */
    //FIXME: layout should be aligned with normal settings view
    private func AdvancedTabView() -> some View {
        return VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                
                Text("License Information")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 16)
            
            Divider()
            
            ScrollView {
                HStack(spacing: 10) {
                    Text(appLicenseText+"\n"+thirdPartyLicenseText)
                    Spacer(minLength: 1) // force full width
                }
            }
            .frame(maxHeight: .infinity) // let the view span the max. height
            //.padding(.all, 10)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.darkGray).opacity(0.3) : Color.blue.opacity(0.05))
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func handleKeyRecorded(keyCode: UInt32, modifiers: UInt32) {
        let newConfig = HotKeyConfiguration(keyCode: keyCode, modifiers: modifiers)
        
        if newConfig.isValid {
            withAnimation {
                currentHotkey = newConfig
                SettingsService.shared.hotKeyConfiguration = newConfig
                
                // Show success indicator temporarily
                showSuccessIndicator = true
                
                // Hide after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showSuccessIndicator = false
                    }
                }
            }
        } else {
            showInvalidHotkeyAlert = true
        }
    }

    
    private func displayLicenses() {
        //print(appLicenseText+"\n"+thirdPartyLicenseText)
        selectedTab = .advancedTab
    }
    

}

#Preview {
    HotkeySettingsView()
}
