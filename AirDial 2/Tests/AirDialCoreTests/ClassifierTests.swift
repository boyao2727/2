import Foundation
import AirDialCore

final class ClassifierTests {
    private func hand() -> [Joint: Point2] {
        var p: [Joint: Point2] = [:]
        p[.wrist] = .init(0.5, 0.8)
        p[.thumbCMC] = .init(0.44, 0.72); p[.thumbMP] = .init(0.42, 0.7)
        p[.thumbIP] = .init(0.42, 0.68); p[.thumbTip] = .init(0.43, 0.66)
        let groups: [(Double, Joint, Joint, Joint, Joint)] = [
            (0.46, .indexMCP, .indexPIP, .indexDIP, .indexTip),
            (0.5, .middleMCP, .middlePIP, .middleDIP, .middleTip),
            (0.54, .ringMCP, .ringPIP, .ringDIP, .ringTip),
            (0.58, .littleMCP, .littlePIP, .littleDIP, .littleTip)
        ]
        for (x, m, pip, dip, tip) in groups {
            p[m] = .init(x, 0.6); p[pip] = .init(x, 0.55)
            p[dip] = .init(x, 0.62); p[tip] = .init(x, 0.68)
        }
        return p
    }

    func testForwardIndexAcceptedButUpwardAndSidewaysRejected() {
        var p = hand()
        p[.indexPIP] = .init(0.46, 0.56); p[.indexDIP] = .init(0.46, 0.54)
        p[.indexTip] = .init(0.46, 0.52)
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .pointing)
        p[.indexPIP] = .init(0.46, 0.45); p[.indexDIP] = .init(0.46, 0.35)
        p[.indexTip] = .init(0.46, 0.27)
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .other)
        p[.indexPIP] = .init(0.6, 0.6); p[.indexDIP] = .init(0.7, 0.6)
        p[.indexTip] = .init(0.8, 0.6)
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .other)
    }

    func testJoinedTwoFingerPoseAndSeparatedPair() {
        var p = hand()
        p[.indexPIP] = .init(0.46, 0.56); p[.indexDIP] = .init(0.46, 0.54); p[.indexTip] = .init(0.46, 0.52)
        p[.middlePIP] = .init(0.5, 0.56); p[.middleDIP] = .init(0.5, 0.54); p[.middleTip] = .init(0.5, 0.52)
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .pointing)
        p[.middlePIP] = .init(0.53, 0.56); p[.middleDIP] = .init(0.55, 0.54); p[.middleTip] = .init(0.57, 0.52)
        checkNotEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .pointing)
    }

    func testFistAndThumbsUpAreSeparate() {
        var p = hand()
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .fist)
        p[.thumbIP] = .init(0.42, 0.52); p[.thumbTip] = .init(0.42, 0.4)
        checkEqual(HandClassifier.classify(p, time: 0, handedness: 1)?.pose, .thumbsUp)
    }

    func testMissingOrTinyHandIsRejected() {
        var p = hand()
        p.removeValue(forKey: .indexTip)
        checkNil(HandClassifier.classify(p, time: 0, handedness: 1))
        p = hand().mapValues { $0 * 0.1 }
        checkNil(HandClassifier.classify(p, time: 0, handedness: 1))
    }
}
