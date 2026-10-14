import Foundation

public enum Joint: String, CaseIterable, Sendable {
    case wrist, thumbCMC, thumbMP, thumbIP, thumbTip
    case indexMCP, indexPIP, indexDIP, indexTip
    case middleMCP, middlePIP, middleDIP, middleTip
    case ringMCP, ringPIP, ringDIP, ringTip
    case littleMCP, littlePIP, littleDIP, littleTip
}

/// Conservative 2D pose heuristics. A webcam cannot measure true finger depth; see docs/LIMITATIONS.md.
public enum HandClassifier {
    public static func classify(_ p: [Joint: Point2], time: Double, handedness: Int) -> HandFrame? {
        guard Joint.allCases.allSatisfy({ p[$0] != nil }),
              let wrist = p[.wrist], let index = p[.indexMCP], let middle = p[.middleMCP],
              let little = p[.littleMCP], let indexTip = p[.indexTip],
              let thumbTip = p[.thumbTip], let thumbIP = p[.thumbIP] else { return nil }
        let scale = wrist.distance(to: middle)
        guard scale > 0.055, scale < 0.6 else { return nil }
        func extended(_ m: Joint, _ pip: Joint, _ dip: Joint, _ tip: Joint) -> Bool {
            let a = p[pip]! - p[m]!, b = p[tip]! - p[pip]!
            let straight = a.dot(b) > 0.45 * a.length * b.length
            return straight && p[tip]!.distance(to: wrist) > p[pip]!.distance(to: wrist) + scale * 0.12
        }
        let fingers = [extended(.indexMCP, .indexPIP, .indexDIP, .indexTip),
                       extended(.middleMCP, .middlePIP, .middleDIP, .middleTip),
                       extended(.ringMCP, .ringPIP, .ringDIP, .ringTip),
                       extended(.littleMCP, .littlePIP, .littleDIP, .littleTip)]
        let width = index.distance(to: little) / scale
        let spread = (index - wrist).cross(little - wrist)
        let front = handedness != 0 && spread * Double(handedness) > 0
        let thumbUp = thumbTip.y < thumbIP.y - scale * 0.22
            && thumbTip.y < index.y - scale * 0.10
            && abs(thumbTip.x - thumbIP.x) < (thumbIP.y - thumbTip.y) * 0.9

        // A finger aimed at the lens is foreshortened. Reject long upward/sideways projections.
        func forward(_ m: Joint, _ pip: Joint, _ tip: Joint) -> Bool {
            let a = p[pip]! - p[m]!, b = p[tip]! - p[pip]!
            let length = p[tip]!.distance(to: p[m]!)
            return length < scale * 0.88 && length > scale * 0.08
                && a.dot(b) > 0.35 * a.length * b.length
                && (p[tip]! - p[m]!).dot(p[m]! - wrist) > 0
        }
        let indexForward = forward(.indexMCP, .indexPIP, .indexTip)
        let middleForward = forward(.middleMCP, .middlePIP, .middleTip)
        let pairTogether = indexTip.distance(to: p[.middleTip]!) < scale * 0.32
        let volumePose = indexForward && !fingers[2] && !fingers[3]
            && (middleForward ? pairTogether : !fingers[1]) && width > 0.32
        let pose: HandPose
        if volumePose { pose = .pointing }
        else if fingers.allSatisfy({ !$0 }), thumbUp { pose = .thumbsUp }
        else if fingers.allSatisfy({ !$0 }), !thumbUp { pose = .fist }
        else if fingers.filter({ $0 }).count >= 3, width < 0.5 { pose = .sidePalm }
        else if fingers.allSatisfy({ $0 }), width >= 0.5, front { pose = .frontPalm }
        else { pose = .other }

        // Thumb around the pointing axis supplies a wrist-roll proxy in mirrored user coordinates.
        let rollVector = thumbTip - index
        let roll = rollVector.length > scale * 0.22 ? atan2(rollVector.y, rollVector.x) : nil
        let pointer = middleForward && pairTogether ? (indexTip + p[.middleTip]!) * 0.5 : indexTip
        return .init(time: time, pose: pose, wrist: wrist, pointer: pointer,
                     palmScale: scale, rollAngle: roll, handedness: handedness)
    }
}
