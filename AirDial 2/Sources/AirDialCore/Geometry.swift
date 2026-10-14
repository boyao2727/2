import Foundation

public struct Point2: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static func + (a: Self, b: Self) -> Self { .init(a.x + b.x, a.y + b.y) }
    public static func - (a: Self, b: Self) -> Self { .init(a.x - b.x, a.y - b.y) }
    public static func * (a: Self, b: Double) -> Self { .init(a.x * b, a.y * b) }
    public var length: Double { hypot(x, y) }
    public func dot(_ b: Self) -> Double { x * b.x + y * b.y }
    public func cross(_ b: Self) -> Double { x * b.y - y * b.x }
    public func distance(to b: Self) -> Double { (self - b).length }
}

func wrappedAngle(_ value: Double) -> Double {
    var result = value
    while result > .pi { result -= 2 * .pi }
    while result < -.pi { result += 2 * .pi }
    return result
}

public enum GestureAction: String, Equatable, Sendable {
    case volumeUp, volumeDown, next, previous, pause, play
}

public enum HandPose: Equatable, Sendable {
    case pointing, sidePalm, frontPalm, fist, thumbsUp, other
}

/// Coordinates are mirrored user-view coordinates, in image-height units; y points down.
public struct HandFrame: Sendable {
    public var time: Double
    public var pose: HandPose
    public var wrist: Point2
    public var pointer: Point2
    public var palmScale: Double
    public var rollAngle: Double?
    public var handedness: Int
    public init(time: Double, pose: HandPose, wrist: Point2, pointer: Point2,
                palmScale: Double = 0.15, rollAngle: Double? = nil, handedness: Int = 0) {
        self.time = time; self.pose = pose; self.wrist = wrist; self.pointer = pointer
        self.palmScale = palmScale; self.rollAngle = rollAngle; self.handedness = handedness
    }
}

public struct GestureResult: Sendable {
    public var actions: [GestureAction]
    public var circleProgress: Double
    public var direction: Int
    public init(actions: [GestureAction] = [], circleProgress: Double = 0, direction: Int = 0) {
        self.actions = actions; self.circleProgress = circleProgress; self.direction = direction
    }
}
