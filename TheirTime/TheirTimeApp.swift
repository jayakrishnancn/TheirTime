//
//  TheirTimeApp.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 04/04/25.
//

import SwiftUI
import SwiftData

@main
struct TheirTimeApp: App {
    @StateObject private var clockStore = ClockStore()
    private let persistentMenu = PersistentMenuWindow()
    
    init() {
        // Make sure ClockStore is initialized properly
        let store = ClockStore()
        
        // Set up the persistent menu bar window
        persistentMenu.setupMenuBarExtra(
            with: ContentView().environmentObject(store),
            width: 400, 
            height: 600
        )
        
        // Save the store reference
        self._clockStore = StateObject(wrappedValue: store)
    }
    
    var body: some Scene {
        Settings {
            Text("TheirTime Settings")
                .padding()
        }
    }
}
