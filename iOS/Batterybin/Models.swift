import Foundation

struct DeviceEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var rating: Int = 3
    var dateAdded: Date = Date()
    var batteryType: String
    var lastSwap: Date
    var notes: String

    init(id: UUID = UUID(), title: String, rating: Int = 3, dateAdded: Date = Date(), batteryType: String = "", lastSwap: Date = Date(), notes: String = "") {
        self.id = id
        self.title = title
        self.rating = rating
        self.dateAdded = dateAdded
        self.batteryType = batteryType
        self.lastSwap = lastSwap
        self.notes = notes
    }
}
