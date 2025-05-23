//
//  TimeZoneInfo.swift
//  TheirTime
//
//  Created by Jayakrishnan Nampoothiri on 04/04/25.
//
import SwiftUI

struct ClockInfo: Identifiable, Hashable, Codable{
    var id = UUID()
    let name: String
    let identifier: String
    var tags: [String] 
  
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ClockInfo, rhs: ClockInfo) -> Bool {
        return lhs.id == rhs.id
    }
}
