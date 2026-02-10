import Foundation
import SwiftData

@Model
final class UserSettings {
    var cutoffHour: Int = 22
    var cutoffMinute: Int = 00
    var morningNotification: Bool = false
    var middayNotification: Bool = false
    var nightNotification: Bool = false
    
    init(cutoffHour: Int = 22, cutoffMinute: Int = 0, morningNotification: Bool = false, middayNotification: Bool = false, nightNotification: Bool = false){
        self.cutoffHour = cutoffHour
        self.cutoffMinute = cutoffMinute
        self.morningNotification = morningNotification
        self.middayNotification = middayNotification
        self.nightNotification = nightNotification
    }
    
}
