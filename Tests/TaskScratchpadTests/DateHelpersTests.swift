import Testing
import Foundation
@testable import TaskScratchpadCore

@Suite("Date Helpers")
struct DateHelpersTests {

    @Test("Now returns 'now' for recent dates")
    func nowForRecentDates() {
        let now = Date()
        let tenSecondsAgo = now.addingTimeInterval(-10)

        #expect(tenSecondsAgo.relativeString(from: now) == "now")
    }

    @Test("Minutes ago formatting")
    func minutesAgo() {
        let now = Date()

        let oneMinuteAgo = now.addingTimeInterval(-60)
        #expect(oneMinuteAgo.relativeString(from: now) == "1m ago")

        let fiveMinutesAgo = now.addingTimeInterval(-300)
        #expect(fiveMinutesAgo.relativeString(from: now) == "5m ago")

        let thirtyMinutesAgo = now.addingTimeInterval(-1800)
        #expect(thirtyMinutesAgo.relativeString(from: now) == "30m ago")

        let fiftyNineMinutesAgo = now.addingTimeInterval(-3540)
        #expect(fiftyNineMinutesAgo.relativeString(from: now) == "59m ago")
    }

    @Test("Hours ago formatting")
    func hoursAgo() {
        let now = Date()

        let oneHourAgo = now.addingTimeInterval(-3600)
        #expect(oneHourAgo.relativeString(from: now) == "1h ago")

        let twoHoursAgo = now.addingTimeInterval(-7200)
        #expect(twoHoursAgo.relativeString(from: now) == "2h ago")

        let twentyThreeHoursAgo = now.addingTimeInterval(-82800)
        #expect(twentyThreeHoursAgo.relativeString(from: now) == "23h ago")
    }

    @Test("Days ago formatting")
    func daysAgo() {
        let now = Date()

        let oneDayAgo = now.addingTimeInterval(-86400)
        #expect(oneDayAgo.relativeString(from: now) == "1d ago")

        let threeDaysAgo = now.addingTimeInterval(-259200)
        #expect(threeDaysAgo.relativeString(from: now) == "3d ago")

        let sixDaysAgo = now.addingTimeInterval(-518400)
        #expect(sixDaysAgo.relativeString(from: now) == "6d ago")
    }

    @Test("Weeks ago shows date format")
    func weeksAgo() {
        let now = Date()
        let eightDaysAgo = now.addingTimeInterval(-691200)
        let result = eightDaysAgo.relativeString(from: now)

        // Should be a date format, not "Xd ago"
        #expect(!result.contains("d ago"))
        #expect(!result.contains("h ago"))
        #expect(!result.contains("m ago"))
    }

    @Test("Future dates return 'future'")
    func futureDates() {
        let now = Date()
        let tomorrow = now.addingTimeInterval(86400)

        #expect(tomorrow.relativeString(from: now) == "future")
    }

    @Test("Time interval constants are correct")
    func timeIntervalConstants() {
        #expect(TimeInterval.minute == 60)
        #expect(TimeInterval.hour == 3600)
        #expect(TimeInterval.day == 86400)
        #expect(TimeInterval.week == 604800)
    }
}

