import Foundation
import AirDialCore

final class GestureTests {
    private func frame(_ pose: HandPose, _ time: Double, x: Double = 0.5,
                       y: Double = 0.5, pointer: Point2? = nil, roll: Double? = nil, hand: Int = 1) -> HandFrame {
        .init(time: time, pose: pose, wrist: .init(x, y), pointer: pointer ?? .init(x, y - 0.1),
              palmScale: 0.15, rollAngle: roll, handedness: hand)
    }

    func testClockwiseAndCounterclockwiseFullTurns() {
        for sign in [1.0, -1.0] {
            var engine = GestureEngine()
            var actions: [GestureAction] = []
            for step in 0...180 {
                let angle = Double(step) * 2 * .pi / 60 * sign
                let p = Point2(0.6 + cos(angle) * 0.08, 0.4 + sin(angle) * 0.08)
                actions += engine.process(frame(.pointing, Double(step) * 0.05, pointer: p)).actions
            }
            checkEqual(actions, Array(repeating: sign > 0 ? .volumeUp : .volumeDown, count: 3))
        }
    }

    func testIncompleteCircleDoesNotChangeVolume() {
        var engine = GestureEngine()
        for step in 0..<45 {
            let angle = Double(step) * 2 * .pi / 60
            let p = Point2(0.6 + cos(angle) * 0.08, 0.4 + sin(angle) * 0.08)
            checkTrue(engine.process(frame(.pointing, Double(step) * 0.05, pointer: p)).actions.isEmpty)
        }
    }

    func testStraightLineAndJitterAreNotCircles() {
        var straight = CircleTracker(), jitter = CircleTracker()
        for step in 0..<180 {
            checkEqual(straight.update(.init(Double(step) * 0.002, 0.4)), 0)
            checkEqual(jitter.update(.init(0.5 + sin(Double(step)) * 0.002, 0.5 + cos(Double(step) * 1.7) * 0.002)), 0)
        }
    }

    func testLongEllipseIsRejected() {
        var circle = CircleTracker()
        for step in 0...180 {
            let a = Double(step) * 2 * .pi / 60
            checkEqual(circle.update(.init(0.5 + cos(a) * 0.12, 0.5 + sin(a) * 0.025)), 0)
        }
    }

    func testWristOnlyTurnsInBothDirections() {
        for sign in [1.0, -1.0] {
            var engine = GestureEngine()
            var actions: [GestureAction] = []
            for step in 0...120 {
                let angle = Double(step) * 2 * .pi / 60 * sign
                actions += engine.process(frame(.pointing, Double(step) * 0.05, roll: angle)).actions
            }
            checkEqual(actions, Array(repeating: sign > 0 ? .volumeUp : .volumeDown, count: 2))
        }
    }

    func testTrajectoryAndWristAreNeverCountedTwice() {
        var engine = GestureEngine()
        var actions: [GestureAction] = []
        for step in 0...120 {
            let a = Double(step) * 2 * .pi / 60
            let p = Point2(0.6 + cos(a) * 0.08, 0.4 + sin(a) * 0.08)
            actions += engine.process(frame(.pointing, Double(step) * 0.05, pointer: p, roll: a)).actions
        }
        checkEqual(actions, [.volumeUp, .volumeUp])
    }

    func testGapAndHandSwitchDiscardPartialTurn() {
        for switchHand in [true, false] {
            var engine = GestureEngine()
            var actions: [GestureAction] = []
            for step in 0...60 {
                let a = Double(step) * 2 * .pi / 60
                let p = Point2(0.6 + cos(a) * 0.08, 0.4 + sin(a) * 0.08)
                let time = Double(step) * 0.05 + (!switchHand && step >= 30 ? 0.5 : 0)
                actions += engine.process(frame(.pointing, time, pointer: p, hand: switchHand && step >= 30 ? -1 : 1)).actions
            }
            checkTrue(actions.isEmpty)
        }
    }

    func testOnlySidePalmCanSwipeAndReturnIsDebounced() {
        for pose in [HandPose.sidePalm, .frontPalm, .pointing, .other] {
            var engine = GestureEngine()
            var actions: [GestureAction] = []
            for step in 0...20 {
                let x = step <= 10 ? 0.2 + Double(step) * 0.03 : 0.5 - Double(step - 10) * 0.03
                actions += engine.process(frame(pose, Double(step) * 0.04, x: x)).actions
            }
            checkEqual(actions, pose == .sidePalm ? [.next] : [])
        }
    }

    func testLeftSwipeAndVerticalMovement() {
        var left = GestureEngine(), vertical = GestureEngine()
        var leftActions: [GestureAction] = [], verticalActions: [GestureAction] = []
        for step in 0...12 {
            leftActions += left.process(frame(.sidePalm, Double(step) * 0.04, x: 0.8 - Double(step) * 0.03)).actions
            verticalActions += vertical.process(frame(.sidePalm, Double(step) * 0.04, y: 0.2 + Double(step) * 0.03)).actions
        }
        checkEqual(leftActions, [.previous]); checkTrue(verticalActions.isEmpty)
    }

    func testTrackingLossCannotBypassSwipeCooldown() {
        var engine = GestureEngine()
        var actions: [GestureAction] = []
        for step in 0...10 {
            actions += engine.process(frame(.sidePalm, Double(step) * 0.04, x: 0.2 + Double(step) * 0.03)).actions
        }
        _ = engine.process(nil)
        for step in 11...24 {
            actions += engine.process(frame(.sidePalm, Double(step) * 0.04, x: 0.8 - Double(step - 11) * 0.03)).actions
        }
        checkEqual(actions, [.next])
    }

    func testPauseNeedsOpenPalmThenFistAndDoesNotRepeat() {
        var engine = GestureEngine()
        for step in 0...20 { checkTrue(engine.process(frame(.fist, Double(step) * 0.05)).actions.isEmpty) }
        for step in 21...28 { _ = engine.process(frame(.frontPalm, Double(step) * 0.05)) }
        var actions: [GestureAction] = []
        for step in 29...70 { actions += engine.process(frame(.fist, Double(step) * 0.05)).actions }
        checkEqual(actions, [.pause])
    }

    func testThumbsUpHasHoldThresholdAndLatch() {
        var engine = GestureEngine()
        var actions: [GestureAction] = []
        for step in 0...40 {
            let result = engine.process(frame(.thumbsUp, Double(step) * 0.05))
            if step < 10 { checkTrue(result.actions.isEmpty) }
            actions += result.actions
        }
        checkEqual(actions, [.play])
    }

    func testResetCancelsPauseArmingAndCircle() {
        var engine = GestureEngine()
        for step in 0...8 { _ = engine.process(frame(.frontPalm, Double(step) * 0.05)) }
        _ = engine.process(nil)
        for step in 9...25 { checkTrue(engine.process(frame(.fist, Double(step) * 0.05)).actions.isEmpty) }
    }

    func testPreferencesPersistAndDefaultToAutomatic() {
        let name = "AirDialTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let first = Preferences(defaults: defaults)
        checkTrue(first.enableOnLaunch)
        first.enableOnLaunch = false; first.language = .chinese
        let second = Preferences(defaults: defaults)
        checkFalse(second.enableOnLaunch); checkEqual(second.language, .chinese)
        checkEqual(AppLanguage.initial(preferred: ["zh-Hans-CN"]), .chinese)
        checkEqual(AppLanguage.initial(preferred: ["en-US"]), .english)
        checkEqual(AppLanguage.initial(preferred: ["fr-FR"]), .english)
    }
}
