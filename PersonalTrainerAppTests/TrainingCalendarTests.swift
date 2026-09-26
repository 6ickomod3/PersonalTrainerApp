import Foundation
import Testing
@testable import PersonalTrainerApp

struct TrainingCalendarTests {
    @Test func monthStartsUnderTheCorrectWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let september = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        calendar.firstWeekday = 2
        let mondayFirst = TrainingCalendar.days(in: september, calendar: calendar)
        #expect(mondayFirst.prefix(while: { $0 == nil }).count == 1)
        #expect(mondayFirst.compactMap { $0 }.count == 30)
        calendar.firstWeekday = 1
        let sundayFirst = TrainingCalendar.days(in: september, calendar: calendar)
        #expect(sundayFirst.prefix(while: { $0 == nil }).count == 2)
        #expect(sundayFirst.compactMap { $0 }.first == september)
    }

    @Test func leapFebruaryHas29Days() throws {
        let calendar = Calendar(identifier: .gregorian)
        let month = try #require(calendar.date(from: DateComponents(year: 2028, month: 2, day: 15)))
        #expect(TrainingCalendar.days(in: month, calendar: calendar).compactMap { $0 }.count == 29)
    }
}
