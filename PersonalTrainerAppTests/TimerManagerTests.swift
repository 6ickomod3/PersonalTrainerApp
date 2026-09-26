import Foundation
import Testing
@testable import PersonalTrainerApp

@MainActor
struct TimerManagerTests {
    private final class Clock {
        var date = Date(timeIntervalSince1970: 1_700_000_000)
        func advance(_ seconds: TimeInterval) { date.addTimeInterval(seconds) }
    }

    private func makeTimer(_ clock: Clock, duration: Int = 90) -> TimerManager {
        TimerManager(
            initialDuration: duration,
            now: { clock.date },
            enablesExternalEffects: false,
            automaticallyTicks: false
        )
    }

    @Test func pauseUsesDeadlineAndResumePreservesRemainingTime() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        clock.advance(12.2)
        // Pause must capture elapsed time even when the display has not ticked.
        timer.pause()
        #expect(!timer.isRunning)
        #expect(timer.secondsRemaining == 78)

        clock.advance(100)
        timer.start()
        clock.advance(10)
        timer.synchronize()
        #expect(timer.isRunning)
        #expect(timer.secondsRemaining == 68)
    }

    @Test func defaultsApplyImmediatelyWhenIdleAndAfterResetWhenRunning() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.updateDefaultDuration(120)
        #expect(timer.secondsRemaining == 120)
        timer.start()
        clock.advance(20)
        timer.synchronize()
        timer.updateDefaultDuration(60)
        #expect(timer.secondsRemaining == 100)
        timer.reset()
        #expect(timer.secondsRemaining == 60)
        #expect(!timer.isRunning)
        #expect(!timer.isFinished)
    }

    @Test func newDefaultDoesNotOverwritePausedRest() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        clock.advance(10)
        timer.pause()
        timer.updateDefaultDuration(180)
        #expect(timer.secondsRemaining == 80)
        timer.reset()
        #expect(timer.secondsRemaining == 180)
    }

    @Test func completionStaysVisibleAndNextStartUsesNewDefault() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        timer.updateDefaultDuration(120)
        clock.advance(90)
        timer.synchronize()
        #expect(timer.isFinished)
        #expect(!timer.isRunning)
        #expect(timer.secondsRemaining == 0)
        timer.start()
        #expect(timer.isRunning)
        #expect(!timer.isFinished)
        #expect(timer.secondsRemaining == 120)
    }

    @Test func foregroundReconcilesExpiredBackgroundRestOnlyOnce() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        timer.setApplicationActive(false)
        clock.advance(300)
        timer.setApplicationActive(true)
        #expect(timer.isFinished)
        #expect(timer.secondsRemaining == 0)
        #expect(!timer.isRunning)
        timer.synchronize()
        timer.setApplicationActive(true)
        #expect(timer.isFinished)
        #expect(timer.secondsRemaining == 0)
    }

    @Test func foregroundKeepsUnexpiredDeadline() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        timer.setApplicationActive(false)
        clock.advance(25)
        timer.setApplicationActive(true)
        #expect(timer.isRunning)
        #expect(timer.secondsRemaining == 65)
    }

    @Test func adjustmentExtendsDeadlineAndResetDuration() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        clock.advance(10.5)
        timer.addTime(15)
        #expect(timer.secondsRemaining == 95)
        clock.advance(10)
        timer.synchronize()
        #expect(timer.secondsRemaining == 85)
        timer.reset()
        #expect(timer.secondsRemaining == 105)
        // A repeated view update must not erase the local adjustment.
        timer.updateDefaultDuration(90)
        #expect(timer.secondsRemaining == 105)
    }

    @Test func subtractingPastZeroCompletesWithoutNegativeTime() {
        let clock = Clock()
        let timer = makeTimer(clock, duration: 10)
        timer.start()
        timer.addTime(-15)
        #expect(timer.secondsRemaining == 0)
        #expect(timer.isFinished)
        #expect(!timer.isRunning)
        timer.start()
        #expect(timer.secondsRemaining > 0)
        #expect((0...1).contains(timer.progress))
    }

    @Test func resettingAppSettingsClearsAdjustmentsEvenWithSameDefault() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.addTime(15)
        timer.start()
        clock.advance(10)
        timer.resetToDefaultDuration(90)
        #expect(timer.secondsRemaining == 90)
        #expect(!timer.isRunning)
        #expect(!timer.isFinished)
        timer.start()
        clock.advance(90)
        timer.synchronize()
        #expect(timer.isFinished)
        timer.reset()
        #expect(timer.secondsRemaining == 90)
    }

    @Test func repeatedStartCannotMoveTheDeadline() {
        let clock = Clock()
        let timer = makeTimer(clock)
        timer.start()
        clock.advance(10)
        timer.start()
        timer.synchronize()
        #expect(timer.secondsRemaining == 80)
    }
}
