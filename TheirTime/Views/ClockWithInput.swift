//
//  ClockWithInput.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 04/04/25.
//

import SwiftUI

struct ClockWithInput: View {
    @Binding var epochSeconds: Int
    let clockInfo: ClockInfo
    @State private var timeString: String
    @State private var dateString: String // Added for date
    @FocusState private var isTimeFieldFocused: Bool
    @FocusState private var isDateFieldFocused: Bool // Added for date field focus

    private var timezone: TimeZone
    private let shouldFocusOnAppear: Bool

    init(epochSeconds: Binding<Int>, clockInfo: ClockInfo, shouldFocusOnAppear: Bool = false) {
        self._epochSeconds = epochSeconds
        self.clockInfo = clockInfo
        self.timezone = TimeZone(identifier: clockInfo.identifier) ?? TimeZone.current
        self.shouldFocusOnAppear = shouldFocusOnAppear
        
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds.wrappedValue))
        
        // Initialize timeString
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timezone
        timeFormatter.dateFormat = "HH:mm:ss"
        self._timeString = State(initialValue: timeFormatter.string(from: date))
        
        // Initialize dateString
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timezone
        dateFormatter.dateFormat = "yyyy/MM/dd"
        self._dateString = State(initialValue: dateFormatter.string(from: date))
    }

    var body: some View {
        VStack {
            AnalogClockView(epochSeconds: epochSeconds, timezone: TimeZone(identifier: clockInfo.identifier)!, name: clockInfo.name)
            
            // Date TextField
            HStack {
                TextField("yyyy/MM/dd", text: $dateString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100) // Adjusted width for date
                    .font(Font.system(size: 12, design: .default))
                    .focused($isDateFieldFocused)
                    .onChange(of: dateString) { oldValue, newValue in
                        if oldValue.count < newValue.count {
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 0 {
                                var formattedDate = ""
                                let limitedDigits = String(digits.prefix(8)) // yyyyMMdd
                                
                                for (index, char) in limitedDigits.enumerated() {
                                    if index == 4 || index == 6 {
                                        formattedDate += "/"
                                    }
                                    formattedDate += String(char)
                                }
                                if formattedDate != newValue {
                                    dateString = formattedDate
                                }
                            }
                        }
                    }
                    .onSubmit {
                        setYYYYMMDDtoEpoch(dateStringInYYYYMMDD: dateString)
                    }
            }

            HStack {
                TextField("HH:mm:ss", text: $timeString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .font(Font.system(size: 12, design: .default))
                    .focused($isTimeFieldFocused)
                    .onChange(of: timeString) { oldValue, newValue in
                        // Only process if user is typing (not when app updates the field)
                        if oldValue.count < newValue.count {
                            // Filter to keep only digits
                            let digits = newValue.filter { $0.isNumber }
                            
                            // Format digits to HH:mm:ss
                            if digits.count > 0 {
                                var formattedTime = ""
                                
                                // Only take first 6 digits (HH:MM:SS)
                                let limitedDigits = String(digits.prefix(6))
                                
                                // Add colons at appropriate positions
                                for (index, char) in limitedDigits.enumerated() {
                                    if index == 2 || index == 4 {
                                        formattedTime += ":"
                                    }
                                    formattedTime += String(char)
                                }
                                
                                // Only update if the format changed
                                if formattedTime != newValue {
                                    timeString = formattedTime
                                }
                            }
                        }
                    }
                    .onSubmit {
                        setHHMMtoEpoch(timeStringInHHMM: timeString)
                    }
            }
        }
        .padding(.top, 5)
        .onChange(of: epochSeconds) { oldValue, newValue in
            // Update timeString when epochSeconds changes from outside
            let date = Date(timeIntervalSince1970: TimeInterval(newValue))
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = timezone
            timeFormatter.dateFormat = "HH:mm:ss"
            timeString = timeFormatter.string(from: date)

            // Update dateString when epochSeconds changes from outside
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = timezone
            dateFormatter.dateFormat = "yyyy/MM/dd"
            dateString = dateFormatter.string(from: date)
        }
        .onAppear {
            let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
            
            // Ensure timeString is set on initial appearance
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = timezone
            timeFormatter.dateFormat = "HH:mm:ss"
            timeString = timeFormatter.string(from: date)

            // Ensure dateString is set on initial appearance
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = timezone
            dateFormatter.dateFormat = "yyyy/MM/dd"
            dateString = dateFormatter.string(from: date)
            
            if shouldFocusOnAppear {
                // Decide which field to focus, or perhaps focus the date field first
                // For now, let's keep the original behavior for time field focus if needed,
                // or you can change it to isDateFieldFocused = true
                isTimeFieldFocused = true
            }
        }
    }

    func setHHMMtoEpoch(timeStringInHHMM: String) {
        let input = timeStringInHHMM.trimmingCharacters(in: .whitespaces)
        
        // Parse the input into components
        var hours = 0
        var minutes = 0
        var seconds = 0
        
        if input.isEmpty {
            print("Empty time string")
            return
        }
        
        let components = input.components(separatedBy: ":")
        
        // Parse hours (allow single digit)
        if let h = Int(components[0]) {
            hours = h
            if hours < 0 || hours > 23 {
                print("Invalid hours value: \(hours)")
                return
            }
        } else {
            print("Invalid hours format")
            return
        }
        
        // Parse minutes if provided, otherwise default to 00
        if components.count > 1 && !components[1].isEmpty {
            if let m = Int(components[1]) {
                // For single-digit minutes, treat as tens (e.g., 1 → 10, 5 → 50)
                if components[1].count == 1 {
                    minutes = m * 10
                } else {
                    minutes = m
                }
                    
                if minutes < 0 || minutes > 59 {
                    print("Invalid minutes value: \(minutes)")
                    return
                }
            } else {
                print("Invalid minutes format")
                return
            }
        }
        
        // Parse seconds if provided
        if components.count > 2 && !components[2].isEmpty {
            if let s = Int(components[2]) {
                seconds = s
                if seconds < 0 || seconds > 59 {
                    print("Invalid seconds value: \(seconds)")
                    return
                }
            } else {
                print("Invalid seconds format")
                return
            }
        }
        
        // Get the current date components using the original epoch time
        let currentDate = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(in: timezone, from: currentDate)
        
        // Update time components
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds
        
        // Create a new date from the combined components
        if let newDate = calendar.date(from: dateComponents) {
            let newEpochSeconds = Int(newDate.timeIntervalSince1970)
            epochSeconds = newEpochSeconds
            
            // Update the timeString to match the new time
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "HH:mm:ss"
            timeString = formatter.string(from: newDate)
            
            print("New epoch time set to: \(newEpochSeconds)")
        }
    }

    func setYYYYMMDDtoEpoch(dateStringInYYYYMMDD: String) {
        let input = dateStringInYYYYMMDD.trimmingCharacters(in: .whitespaces)
        
        guard !input.isEmpty else {
            print("Empty date string")
            return
        }
        
        let components = input.components(separatedBy: "/")
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            print("Invalid date format. Expected yyyy/MM/dd")
            return
        }

        if year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 || day > 31 { // Basic validation
            print("Invalid date components: Year: \(year), Month: \(month), Day: \(day)")
            return
        }

        // Get the current time components using the original epoch time
        let currentDate = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(in: timezone, from: currentDate) // Preserves HH:mm:ss

        // Update date components
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        // Create a new date from the combined components
        if let newDate = calendar.date(from: dateComponents) {
            let newEpochSeconds = Int(newDate.timeIntervalSince1970)
            epochSeconds = newEpochSeconds
            
            // Update the dateString to match the new date (e.g. if user entered 2023/1/1 -> 2023/01/01)
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "yyyy/MM/dd"
            dateString = formatter.string(from: newDate)
            
            print("New epoch time set to: \(newEpochSeconds) based on new date")
        } else {
            print("Could not create new date from components")
        }
    }
}

