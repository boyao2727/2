import Foundation

/// Fits a circular path before integrating phase. Straight swipes and elongated ellipses fail the fit.
public struct CircleTracker {
    private var points: [Point2] = []
    private var center: Point2?
    private var radius = 0.0
    private var accumulated = 0.0
    private var last: Point2?
    public private(set) var progress = 0.0
    public private(set) var direction = 0

    public init() {}
    public mutating func reset() { self = .init() }

    public mutating func update(_ point: Point2) -> Int {
        if let last, point.distance(to: last) > 0.24 { reset() }
        points.append(point)
        if points.count > 180 { points.removeFirst() }
        defer { last = point }

        if center == nil {
            guard points.count >= 10, let fit = fitCircle(points) else { return 0 }
            // At least 100 degrees of consistent travel is needed before accepting a center.
            var angle = 0.0
            for pair in zip(points, points.dropFirst()) {
                let a = pair.0 - fit.0, b = pair.1 - fit.0
                angle += atan2(a.cross(b), a.dot(b))
            }
            guard abs(angle) >= 1.75 else { return 0 }
            center = fit.0; radius = fit.1; accumulated = angle
        } else if let center, let last {
            let a = last - center, b = point - center
            guard abs(b.length - radius) < radius * 0.55 else { reset(); return 0 }
            let delta = atan2(a.cross(b), a.dot(b))
            guard abs(delta) < 0.8 else { reset(); return 0 }
            accumulated += delta
        }
        direction = accumulated >= 0 ? 1 : -1
        let turn = 2 * Double.pi
        var emitted = 0
        if abs(accumulated) >= turn - 0.06 {
            emitted = direction
            accumulated -= Double(direction) * turn
        }
        progress = min(1, abs(accumulated) / turn)
        return emitted
    }

    private func fitCircle(_ pts: [Point2]) -> (Point2, Double)? {
        let mean = pts.reduce(Point2(0, 0), +) * (1 / Double(pts.count))
        let local = pts.map { $0 - mean }
        var xx = 0.0, xy = 0.0, yy = 0.0, xz = 0.0, yz = 0.0
        for p in local {
            let z = p.x * p.x + p.y * p.y
            xx += p.x * p.x; xy += p.x * p.y; yy += p.y * p.y
            xz += p.x * z; yz += p.y * z
        }
        let det = xx * yy - xy * xy
        guard det > 1e-10 else { return nil }
        let c = Point2((xz * yy - yz * xy) / (2 * det),
                       (yz * xx - xz * xy) / (2 * det)) + mean
        let radii = pts.map { $0.distance(to: c) }
        let r = radii.reduce(0, +) / Double(pts.count)
        guard (0.025...0.28).contains(r) else { return nil }
        let error = sqrt(radii.reduce(0) { $0 + pow($1 - r, 2) } / Double(pts.count)) / r
        guard error < 0.15 else { return nil }
        return (c, r)
    }
}
