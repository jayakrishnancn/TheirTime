import SwiftUI
import AppKit

class PersistentMenuWindow: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var isPopoverShown = false
    
    func setupMenuBarExtra<Content: View>(with view: Content, width: CGFloat = 400, height: CGFloat = 600) {
        // Create the SwiftUI view
        let hostingController = NSHostingController(rootView: view)
        
        // Create a popover
        let popover = NSPopover()
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: width, height: height)
        popover.behavior = .transient
        self.popover = popover
        
        // Create the status item
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusBarButton = self.statusItem?.button {
            statusBarButton.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "TheirTime")
            statusBarButton.target = self
            statusBarButton.action = #selector(togglePopover(_:))
        }
        
        // Create an event monitor to detect clicks outside the popover
        self.eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isPopoverShown else { return }
            
            // Close the popover when clicking outside, unless it's handled by a SwiftUI control
            if let popover = self.popover, 
               popover.isShown, 
               !NSApp.isActive {
                self.hidePopover(nil)
            }
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover = self.popover {
            if popover.isShown {
                hidePopover(sender)
            } else {
                showPopover(sender)
            }
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let statusBarButton = self.statusItem?.button {
            if let popover = self.popover {
                popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
                self.isPopoverShown = true
                
                // This is crucial - makes the app active so clicks inside are handled properly
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func hidePopover(_ sender: AnyObject?) {
        if let popover = self.popover {
            popover.performClose(sender)
            self.isPopoverShown = false
        }
    }
    
    deinit {
        if let eventMonitor = self.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}