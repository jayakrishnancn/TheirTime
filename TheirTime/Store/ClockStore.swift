//
//  ClockStore.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 05/04/25.
//


import SwiftUI


class ClockStore: ObservableObject {
    @Published var clocks: [ClockInfo] = []
    
    private let userDefaultsKey = "savedClocks"

    init() {
        loadClocks()
    }

    func addClock(_ clock: ClockInfo) {
        clocks.append(clock)
        saveClocks()
    }
    
    func removeClock(_ clock: ClockInfo) {
        if let index = clocks.firstIndex(where: { $0.id == clock.id }) {
            clocks.remove(at: index)
            saveClocks()
        }
    }
    
    func addTag(to clockId: UUID, tag: String) {
        if let index = clocks.firstIndex(where: { $0.id == clockId }) {
            var updatedClock = clocks[index]
            if !updatedClock.tags.contains(tag) {
                updatedClock.tags.append(tag)
                clocks[index] = updatedClock
                saveClocks() // Save after modifying
            }
        }
    }
    func removeTag(from clockId: UUID, tag: String) {
        if let index = clocks.firstIndex(where: { $0.id == clockId }) {
            var updatedTags = clocks[index].tags
            updatedTags.removeAll(where: { $0 == tag })
            clocks[index].tags = updatedTags
            saveClocks()
        }
    }
    
    func saveClocks() {
        if let encoded = try? JSONEncoder().encode(clocks) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // Export clocks data
    func exportClocksData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encodedData = try encoder.encode(clocks)
            return encodedData
        } catch {
            print("ClockStore: Failed to encode clocks data: \(error)")
            return nil
        }
    }
    
    // Import clocks from a file
    func importClocks(from url: URL) -> Bool {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("ClockStore: Failed to start accessing security-scoped resource for URL: \(url)")
            return false
        }

        defer {
            // Stop accessing the security-scoped resource
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedClocks = try decoder.decode([ClockInfo].self, from: data)
            
            // Merge the imported clocks with existing ones, avoiding duplicates
            for importedClock in importedClocks {
                if !self.clocks.contains(where: { $0.identifier == importedClock.identifier && $0.name == importedClock.name }) {
                    self.clocks.append(importedClock)
                }
            }
            
            saveClocks()
            return true
        } catch {
            print("Failed to import clocks: \(error)")
            return false
        }
    }
    
    func loadClocks() {
        if let savedClocks = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedClocks = try? JSONDecoder().decode([ClockInfo].self, from: savedClocks) {
            clocks = decodedClocks
        } else {
            // Initialize with default clocks if no saved data
            clocks = [
                ClockInfo(name: "PST", identifier: "America/Los_Angeles", tags: []),
                ClockInfo(name: "EST", identifier: "America/New_York", tags: []),
                ClockInfo(name: "IST", identifier: "Asia/Kolkata", tags: []),
            
            ]
            saveClocks() // Save the defaults for next launch
        }
    }
}
