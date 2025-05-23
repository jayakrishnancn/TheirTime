import SwiftUI

struct AnalogClockView: View {
    let epochSeconds: Int
    let timezone: TimeZone
    let name: String?
    
    // Computed properties to get time components from epoch
    private var hours: Int {
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.component(.hour, from: date)
    }
    
    private var minutes: Int {
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.component(.minute, from: date)
    }
    
    private var seconds: Int {
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.component(.second, from: date)
    }
    
    // Convert time to angles for clock hands
    private var hourAngle: Double {
        let hourIn12Format = Double(hours % 12)
        let minuteContribution = Double(minutes) / 60.0
        return (hourIn12Format + minuteContribution) * (2 * .pi / 12)
    }
    
    private var minuteAngle: Double {
        Double(minutes) * (2 * .pi / 60) + (Double(seconds) / 60.0) * (2 * .pi / 60)
    }
    
    private var secondAngle: Double {
        Double(seconds) * (2 * .pi / 60)
    }
    
    // Simplified initializer
    init(epochSeconds: Int, timezone: TimeZone, name: String? = nil) {
        self.epochSeconds = epochSeconds
        self.timezone = timezone
        self.name = name
    }
    
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let radius = diameter / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Clock face
                Circle()
                    .stroke(Color.gray, lineWidth: radius * 0.03)
                    .background(Circle().fill(Color.white))
                
                // Hour markers
                ForEach(0..<12) { hour in
                    Rectangle()
                        .fill(Color.black)
                        .frame(
                            width: radius * 0.02, 
                            height: hour % 3 == 0 ? radius * 0.13 : radius * 0.06
                        )
                        .offset(y: -radius * 0.9)
                        .rotationEffect(Angle.degrees(Double(hour) * 30))
                }
                
                ForEach(1...12, id: \.self) { hour in
                    Text("\(hour)")
                        .font(.system(size: radius * 0.15, weight: .bold))
                        .position(
                            x: radius * 0.75 * sin(Double(hour) * .pi / 6) + center.x,
                            y: -radius * 0.75 * cos(Double(hour) * .pi / 6) + center.y
                        )
                }
                
                // AM/PM indicator for 24-hour format
                Text(hours < 12 ? "AM" : "PM")
                    .font(.system(size: radius * 0.15))
                    .offset(y: -radius * 0.25)
                
                // Timezone indicator
                Text(name ?? timezone.identifier.components(separatedBy: "/").last ?? timezone.identifier)
                    .font(.system(size: radius * 0.12))
                    .lineLimit(1)
                    .offset(y: radius * 0.25)
                
                // Hour hand
                Rectangle()
                    .fill(Color.black)
                    .frame(width: radius * 0.05, height: radius * 0.45)
                    .cornerRadius(radius * 0.02)
                    .offset(y: -radius * 0.225)
                    .rotationEffect(Angle.radians(hourAngle))
                
                // Minute hand
                Rectangle()
                    .fill(Color.black)
                    .frame(width: radius * 0.04, height: radius * 0.6)
                    .cornerRadius(radius * 0.015)
                    .offset(y: -radius * 0.3)
                    .rotationEffect(Angle.radians(minuteAngle))
                
                // Second hand
                Rectangle()
                    .fill(Color.red)
                    .frame(width: radius * 0.02, height: radius * 0.7)
                    .offset(y: -radius * 0.35)
                    .rotationEffect(Angle.radians(secondAngle))
                
                // Center cap
                Circle()
                    .fill(Color.black)
                    .frame(width: radius * 0.08, height: radius * 0.08)
            }
            .position(center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
