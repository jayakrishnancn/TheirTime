//
//  ContentView.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 04/04/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @StateObject private var clockStore = ClockStore()
    @State private var time = Int(Date().timeIntervalSince1970)
    @State private var searchText = ""
    @State private var showAddClockSheet = false
    @State private var newClockTimeZone = TimeZone.current.identifier
    @State private var newClockName = ""
    @State private var clockToDelete: ClockInfo?
    @State private var showingDeleteAlert = false
    @State private var timeZoneSearchText = ""
    @State private var isLiveClockEnabled = false
    @State private var epochString: String = ""
    @State private var showImportExportSheet = false
    @FocusState private var isEpochFieldFocused: Bool
    
    private func deleteClockWithConfirmation(_ clock: ClockInfo) {
        clockToDelete = clock
        showingDeleteAlert = true
    }
    
    var filteredClocks: [ClockInfo] {
        if searchText.isEmpty {
            return clockStore.clocks
        } else {
            let searchTerms = searchText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            return clockStore.clocks.filter { clock in
                searchTerms.contains { term in
                    let nameMatch = clock.name.localizedCaseInsensitiveContains(term)
                    let tagMatch = clock.tags.contains { tag in
                        tag.localizedCaseInsensitiveContains(term)
                    }
                    return nameMatch || tagMatch
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack{
                Spacer() // Add Spacer to push TextField to the right
                TextField("Epoch", text: $epochString, onCommit: {
                    if var newTimeValue = Int(epochString) {
                        // Heuristic: if the number is very large (e.g., > 30 billion),
                        // assume it's in milliseconds and convert to seconds.
                        // A value of 30,000,000,000 seconds is far in the future (year ~2920).
                        // Current epoch milliseconds are typically 13 digits (e.g., 1.7 * 10^12).
                        if newTimeValue > 30_000_000_000 {
                            newTimeValue /= 1000
                        }
                        time = newTimeValue
                    }
                })
                .focused($isEpochFieldFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            }
            // Main clock
            ClockWithInput(epochSeconds: $time, clockInfo: ClockInfo(name: TimeZone.current.identifier, identifier: TimeZone.current.identifier, tags: []), shouldFocusOnAppear: true)
                .frame(height: 150)
            
            HStack {
                
                
                Toggle(isOn: $isLiveClockEnabled) {
                    Text("Live Clock")
                }
                Spacer()
                
               
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.caption)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                }
                
                Button(action: {
                    showAddClockSheet = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredClocks, id: \.id) { clock in
                        HStack {
                            ClockWithInput(epochSeconds: $time, clockInfo: clock)
                                .frame(width: 150, height: 150)
                            
                            VStack(alignment: .leading) {
                                HStack{
                                Text(clock.name)
                                    .font(.headline)
                                Button(action: {
                                    deleteClockWithConfirmation(clock)
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                }
                                ShowTagsAndManageTagsView(clockInfo: clock)
                                    .frame(maxWidth: 500)
                            }
                            
                          
                            
                            
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            HStack {
                 Button(action: {
                    showImportExportSheet = true
                }) {
                    Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
                
                Spacer()
                Button("Quit TheirTime") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .padding(8)
        .onAppear {
            clockStore.loadClocks()
            epochString = String(time)
            if isLiveClockEnabled {
                startTimer()
            }
        }
        .onChange(of: time) { oldValue, newValue in
            epochString = String(newValue)
        }
        .onChange(of: isLiveClockEnabled) { newValue in
            if newValue {
                startTimer()
            } else {
                // Optionally stop the timer if you were using a Timer directly
            }
        }
        .environmentObject(clockStore)
        .sheet(isPresented: $showAddClockSheet) {
            addClockView
        }
        .sheet(isPresented: $showImportExportSheet) {
            ImportExportView()
                .environmentObject(clockStore) // Ensure the sheet uses the correct ClockStore instance
        }
        .alert(isPresented: $showingDeleteAlert, content: {
            Alert(
                title: Text("Delete Clock"),
                message: Text("Are you sure you want to delete \(clockToDelete?.name ?? "")?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let clockToDelete = clockToDelete {
                        clockStore.removeClock(clockToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        })
    }
    
    private var addClockView: some View {
        VStack(spacing: 4) {
            Text("New Clock")
                .font(.headline)
            
            Form {
                Section {
                    TextField("Clock Name", text: $newClockName)
                    
                    TextField("Search Time Zone", text: $timeZoneSearchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    List {
                        ForEach(filteredTimeZones(searchText: timeZoneSearchText), id: \.self) { timezone in
                            HStack {
                                Text(timezone)
                                Spacer()
                                Text(getCommonTimeZoneAbbreviation(for: timezone))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                newClockTimeZone = timezone
                                timeZoneSearchText = ""
                            }
                            .background(newClockTimeZone == timezone ? Color.blue.opacity(0.2) : Color.clear)
                        }
                    }
                    .frame(height: 200)
                    
                    Text("Selected: \(newClockTimeZone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Button("Cancel") {
                    showAddClockSheet = false
                    resetNewClockFields()
                }
                
                Spacer()
                
                Button("Add") {
                    addNewClock()
                }
                .disabled(newClockName.isEmpty)
            }
            .padding()
        }
        .padding(20)
    }
    
    private func filteredTimeZones(searchText: String) -> [String] {
        let allTimeZones = TimeZone.knownTimeZoneIdentifiers.sorted()
        
        if searchText.isEmpty {
            return allTimeZones
        } else {
            return allTimeZones.filter { timezoneId in
                let idMatch = timezoneId.localizedCaseInsensitiveContains(searchText)
                let commonAbbreviation = getCommonTimeZoneAbbreviation(for: timezoneId)
                let abbreviationMatch = commonAbbreviation.localizedCaseInsensitiveContains(searchText)
                return idMatch || abbreviationMatch
            }
        }
    }
    
    private func resetNewClockFields() {
        newClockName = ""
        newClockTimeZone = TimeZone.current.identifier
    }
    
    private func addNewClock() {
        let newClock = ClockInfo(
            name: newClockName,
            identifier: newClockTimeZone,
            tags: []
        )
        clockStore.addClock(newClock)
        showAddClockSheet = false
        resetNewClockFields()
    }
    
    private func getCommonTimeZoneAbbreviation(for identifier: String) -> String {
        let abbreviationMap: [String: String] = [
            "America/New_York": "EST/EDT",
            "America/Chicago": "CST/CDT",
            "America/Denver": "MST/MDT",
            "America/Los_Angeles": "PST/PDT",
            "America/Phoenix": "MST",
            "America/Anchorage": "AKST/AKDT",
            "America/Juneau": "AKST/AKDT",
            "America/Adak": "HST/HDT",
            "Pacific/Honolulu": "HST",
            "America/Halifax": "AST/ADT",
            "America/St_Johns": "NST/NDT",
            "America/Puerto_Rico": "AST",
            "America/Toronto": "EST/EDT",
            "America/Winnipeg": "CST/CDT",
            "America/Regina": "CST",
            "America/Edmonton": "MST/MDT",
            "America/Vancouver": "PST/PDT",
            "America/Sao_Paulo": "BRT/BRST",
            "America/Argentina/Buenos_Aires": "ART",
            "America/Santiago": "CLT/CLST",
            "America/Bogota": "COT",
            "America/Lima": "PET",
            "America/Caracas": "VET",
            "Europe/London": "GMT/BST",
            "Europe/Dublin": "GMT/IST",
            "Europe/Lisbon": "WET/WEST",
            "Europe/Paris": "CET/CEST",
            "Europe/Brussels": "CET/CEST",
            "Europe/Amsterdam": "CET/CEST",
            "Europe/Berlin": "CET/CEST",
            "Europe/Rome": "CET/CEST",
            "Europe/Stockholm": "CET/CEST",
            "Europe/Vienna": "CET/CEST",
            "Europe/Madrid": "CET/CEST",
            "Europe/Warsaw": "CET/CEST",
            "Europe/Prague": "CET/CEST",
            "Europe/Athens": "EET/EEST",
            "Europe/Istanbul": "TRT",
            "Europe/Moscow": "MSK",
            "Europe/Helsinki": "EET/EEST",
            "Europe/Bucharest": "EET/EEST",
            "Europe/Kiev": "EET/EEST",
            "Asia/Tokyo": "JST",
            "Asia/Seoul": "KST",
            "Asia/Shanghai": "CST",
            "Asia/Hong_Kong": "HKT",
            "Asia/Taipei": "CST",
            "Asia/Singapore": "SGT",
            "Asia/Kuala_Lumpur": "MYT",
            "Asia/Manila": "PHT",
            "Asia/Jakarta": "WIB",
            "Asia/Bangkok": "ICT",
            "Asia/Ho_Chi_Minh": "ICT",
            "Asia/Kolkata": "IST",
            "Asia/Colombo": "IST",
            "Asia/Kathmandu": "NPT",
            "Asia/Dhaka": "BST",
            "Asia/Karachi": "PKT",
            "Asia/Dubai": "GST",
            "Asia/Riyadh": "AST",
            "Asia/Tehran": "IRST/IRDT",
            "Asia/Jerusalem": "IST/IDT",
            "Africa/Cairo": "EET",
            "Africa/Johannesburg": "SAST",
            "Africa/Lagos": "WAT",
            "Africa/Nairobi": "EAT",
            "Africa/Casablanca": "WET/WEST",
            "Australia/Sydney": "AEST/AEDT",
            "Australia/Melbourne": "AEST/AEDT",
            "Australia/Brisbane": "AEST",
            "Australia/Adelaide": "ACST/ACDT",
            "Australia/Darwin": "ACST",
            "Australia/Perth": "AWST",
            "Australia/Hobart": "AEST/AEDT",
            "Pacific/Auckland": "NZST/NZDT",
            "Pacific/Fiji": "FJT/FJST",
            "Pacific/Guam": "ChST"
        ]
        
        if let abbreviation = abbreviationMap[identifier] {
            return abbreviation
        } else {
            return TimeZone(identifier: identifier)?.abbreviation() ?? "Unknown"
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isLiveClockEnabled {
                time = Int(Date().timeIntervalSince1970)
            } else {
                timer.invalidate()
            }
        }
    }
}
