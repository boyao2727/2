import Foundation
import Darwin

var failures: [String] = []

func checkEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #filePath, line: UInt = #line) {
    if actual != expected { failures.append("\(file):\(line): expected \(expected), got \(actual)") }
}
func checkNotEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #filePath, line: UInt = #line) {
    if actual == expected { failures.append("\(file):\(line): unexpected \(actual)") }
}
func checkTrue(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) {
    if !value { failures.append("\(file):\(line): expected true") }
}
func checkFalse(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) {
    if value { failures.append("\(file):\(line): expected false") }
}
func checkNil<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) {
    if value != nil { failures.append("\(file):\(line): expected nil") }
}

let gestures = GestureTests()
let classifier = ClassifierTests()
let checks: [(String, () -> Void)] = [
    ("Clockwise / counterclockwise full turns", gestures.testClockwiseAndCounterclockwiseFullTurns),
    ("Partial circle has no effect", gestures.testIncompleteCircleDoesNotChangeVolume),
    ("Straight paths and jitter rejected", gestures.testStraightLineAndJitterAreNotCircles),
    ("Long ellipses rejected", gestures.testLongEllipseIsRejected),
    ("Wrist rotation both directions", gestures.testWristOnlyTurnsInBothDirections),
    ("Trajectory and wrist counted once", gestures.testTrajectoryAndWristAreNeverCountedTwice),
    ("Tracking gap and hand switch reset", gestures.testGapAndHandSwitchDiscardPartialTurn),
    ("Side-palm swipe and return cooldown", gestures.testOnlySidePalmCanSwipeAndReturnIsDebounced),
    ("Left swipe and vertical rejection", gestures.testLeftSwipeAndVerticalMovement),
    ("Tracking loss cannot bypass swipe cooldown", gestures.testTrackingLossCannotBypassSwipeCooldown),
    ("Open-palm then fist pauses once", gestures.testPauseNeedsOpenPalmThenFistAndDoesNotRepeat),
    ("Thumbs-up hold and latch", gestures.testThumbsUpHasHoldThresholdAndLatch),
    ("No hand clears armed gestures", gestures.testResetCancelsPauseArmingAndCircle),
    ("Preferences and language persistence", gestures.testPreferencesPersistAndDefaultToAutomatic),
    ("Forward index vs ceiling / side", classifier.testForwardIndexAcceptedButUpwardAndSidewaysRejected),
    ("Joined fingers vs spread pair", classifier.testJoinedTwoFingerPoseAndSeparatedPair),
    ("Fist vs thumbs-up", classifier.testFistAndThumbsUpAreSeparate),
    ("Incomplete and small hands rejected", classifier.testMissingOrTinyHandIsRejected)
]
for (name, run) in checks {
    let before = failures.count
    run()
    print("\(failures.count == before ? "PASS" : "FAIL")  \(name)")
}
failures.forEach { print($0) }
print("\(checks.count) checks, \(failures.count) assertion failures")
exit(failures.isEmpty ? 0 : 1)
