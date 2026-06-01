import Foundation

public extension Date {
    func sessionHopperRelativeLabel(now: Date = Date()) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "de_DE")
        timeFormatter.dateFormat = "HH:mm"

        if calendar.isDate(self, inSameDayAs: now) {
            return "heute \(timeFormatter.string(from: self))"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return "gestern \(timeFormatter.string(from: self))"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "dd.MM. HH:mm"
        return dateFormatter.string(from: self)
    }
}
