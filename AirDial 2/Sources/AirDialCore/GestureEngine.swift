import Foundation

/// No camera or system effects here. One serial camera queue owns this state machine.
public struct GestureEngine {
    private var circle = CircleTracker()
    private var mode: HandPose = .other
    private var modeSince = 0.0
    private var lastTime: Double?
    private var lastHand = 0
    private var palmArmedUntil = 0.0
    private var pauseLatched = false
    private var playLatched = false
    private var cooldownUntil = 0.0
    private var swipe: [(Double, Point2)] = []
    private var previousRoll: Double?
    private var rollAccumulated = 0.0
    private var rollAnchor: Point2?
    private var rotationSource = 0 // 0 undecided, 1 trajectory, 2 wrist; never count both.

    public init() {}
    public mutating func reset() { self = .init() }
    private mutating func loseTracking() {
        let cooldown = cooldownUntil
        self = .init()
        cooldownUntil = cooldown
    }

    public mutating func process(_ frame: HandFrame?) -> GestureResult {
        guard let f = frame else { loseTracking(); return .init() }
        if let lastTime, f.time - lastTime > 0.25 || f.time <= lastTime || f.handedness != lastHand {
            loseTracking()
        }
        lastTime = f.time; lastHand = f.handedness
        if f.pose != mode {
            mode = f.pose; modeSince = f.time
            circle.reset(); previousRoll = nil; rollAccumulated = 0; rollAnchor = f.wrist
            rotationSource = 0; swipe.removeAll()
        }
        if f.pose != .fist { pauseLatched = false }
        if f.pose != .thumbsUp { playLatched = false }
        let held = f.time - modeSince
        if f.pose == .pointing || f.pose == .sidePalm || f.pose == .thumbsUp { palmArmedUntil = 0 }

        switch f.pose {
        case .frontPalm:
            if held >= 0.25 { palmArmedUntil = f.time + 1.3 }
        case .fist:
            if held >= 0.45, f.time < palmArmedUntil, !pauseLatched, f.time >= cooldownUntil {
                pauseLatched = true; palmArmedUntil = 0; cooldownUntil = f.time + 0.7
                return .init(actions: [.pause])
            }
        case .thumbsUp:
            if held >= 0.5, !playLatched, f.time >= cooldownUntil {
                playLatched = true; cooldownUntil = f.time + 0.7
                return .init(actions: [.play])
            }
        case .sidePalm:
            guard f.time >= cooldownUntil else { return .init() }
            swipe.append((f.time, f.wrist))
            swipe.removeAll { f.time - $0.0 > 0.65 }
            if let start = swipe.first, f.time - start.0 >= 0.15 {
                let delta = f.wrist - start.1
                if abs(delta.x) > max(0.18, f.palmScale * 1.25), abs(delta.y) < abs(delta.x) * 0.45 {
                    cooldownUntil = f.time + 1.0; swipe.removeAll()
                    return .init(actions: [delta.x > 0 ? .next : .previous])
                }
            }
        case .pointing:
            guard f.time >= cooldownUntil else { return .init() }
            let turn = circle.update(f.pointer)
            if rotationSource == 0, circle.progress > 0.25 || turn != 0 { rotationSource = 1 }
            if rotationSource == 1 {
                return .init(actions: turn == 0 ? [] : [turn > 0 ? .volumeUp : .volumeDown],
                             circleProgress: circle.progress, direction: circle.direction)
            }
            // Wrist rotation is used only while the wrist stays in place. Circle input wins when moving.
            if let angle = f.rollAngle {
                if let prev = previousRoll {
                    let delta = wrappedAngle(angle - prev)
                    if abs(delta) < 0.6 { rollAccumulated += delta }
                    else { rollAccumulated = 0 }
                }
                previousRoll = angle
            }
            if let anchor = rollAnchor, f.wrist.distance(to: anchor) > f.palmScale * 0.45 {
                rollAccumulated = 0; rollAnchor = f.wrist
            }
            if rotationSource == 0, abs(rollAccumulated) > 1.8 { rotationSource = 2 }
            if rotationSource == 2 {
                let sign = rollAccumulated >= 0 ? 1 : -1
                var action: [GestureAction] = []
                if abs(rollAccumulated) >= 2 * .pi - 0.06 {
                    action = [sign > 0 ? .volumeUp : .volumeDown]
                    rollAccumulated -= Double(sign) * 2 * .pi
                }
                return .init(actions: action, circleProgress: abs(rollAccumulated) / (2 * .pi), direction: sign)
            }
            return .init(circleProgress: circle.progress, direction: circle.direction)
        case .other: break
        }
        return .init()
    }
}
