import AVFoundation
import Vision
import AirDialCore

final class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum State { case running, stopped, denied, missing, failed }
    var onState: ((State) -> Void)?
    var onGesture: ((GestureResult) -> Void)?
    var onVisionError: (() -> Void)?
    private let queue = DispatchQueue(label: "app.airdial.camera", qos: .userInitiated)
    private let session = AVCaptureSession()
    private let request = VNDetectHumanHandPoseRequest()
    private var engine = GestureEngine()
    private let lifecycleLock = NSLock()
    private var generation = 0 // Protected by lifecycleLock; invalidates authorization and queued work.
    private var running = false // Camera queue only.
    private var activeTicket = 0 // Camera queue only; prevents stale results after disable/re-enable.
    private var lastFrame = 0.0
    private var visionFailures = 0
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        request.maximumHandCount = 2 // Reject multiple hands instead of silently switching subjects.
        request.revision = VNDetectHumanHandPoseRequestRevision1
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                self?.queue.async { [weak self] in self?.fail() }
            })
        }
    }

    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        let ticket = nextTicket()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: begin(ticket: ticket)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self, self.isCurrent(ticket) else { return }
                    if allowed { self.begin(ticket: ticket) } else { self.onState?(.denied) }
                }
            }
        default: onState?(.denied)
        }
    }

    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))
        let ticket = nextTicket()
        queue.async { [weak self] in
            guard let self else { return }
            self.teardown()
            self.report(.stopped, ticket: ticket)
        }
    }

    /// Waits for all in-flight recognition to finish before process termination.
    func shutdown() {
        _ = nextTicket()
        queue.sync { teardown() }
    }

    private func nextTicket() -> Int {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        generation += 1
        return generation
    }

    private func isCurrent(_ ticket: Int) -> Bool {
        lifecycleLock.lock()
        defer { lifecycleLock.unlock() }
        return generation == ticket
    }

    private func begin(ticket: Int) {
        queue.async { [weak self] in
            guard let self, self.isCurrent(ticket) else { return }
            self.teardown()
            self.activeTicket = ticket
            guard let device = AVCaptureDevice.default(for: .video) else {
                self.report(.missing, ticket: ticket); return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                self.session.beginConfiguration()
                if self.session.canSetSessionPreset(.vga640x480) { self.session.sessionPreset = .vga640x480 }
                guard self.session.canAddInput(input), self.session.canAddOutput(output) else {
                    self.session.commitConfiguration(); self.teardown(); self.report(.failed, ticket: ticket); return
                }
                self.session.addInput(input)
                self.session.addOutput(output)
                output.setSampleBufferDelegate(self, queue: self.queue)
                if let connection = output.connection(with: .video), connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
                self.session.commitConfiguration()
                guard self.isCurrent(ticket) else { self.teardown(); return }
                self.session.startRunning()
                self.running = self.session.isRunning
                self.report(self.running ? .running : .failed, ticket: ticket)
            } catch {
                self.teardown(); self.report(.failed, ticket: ticket)
            }
        }
    }

    private func report(_ state: State, ticket: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isCurrent(ticket) else { return }
            self.onState?(state)
        }
    }

    private func teardown() {
        running = false
        if session.isRunning { session.stopRunning() }
        session.beginConfiguration()
        session.outputs.forEach {
            ($0 as? AVCaptureVideoDataOutput)?.setSampleBufferDelegate(nil, queue: nil)
            session.removeOutput($0)
        }
        session.inputs.forEach { session.removeInput($0) }
        session.commitConfiguration()
        engine.reset(); lastFrame = 0; visionFailures = 0
    }

    private func fail() {
        guard running else { return }
        let ticket = activeTicket
        teardown()
        report(.failed, ticket: ticket)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard running, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = ProcessInfo.processInfo.systemUptime
        guard time - lastFrame >= 1 / 20.0 else { return }
        lastFrame = time
        do {
            // No sample buffers escape this callback. No preview, photo, audio, file or movie output exists.
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up).perform([request])
            visionFailures = 0
            let hands = request.results ?? []
            let frame = hands.count == 1 ? makeFrame(hands[0], pixelBuffer: pixelBuffer, time: time) : nil
            let result = engine.process(frame)
            let ticket = activeTicket
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isCurrent(ticket) else { return }
                self.onGesture?(result)
            }
        } catch {
            engine.reset(); visionFailures += 1
            if visionFailures == 20 {
                let ticket = activeTicket
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.isCurrent(ticket) else { return }
                    self.onVisionError?()
                }
            }
        }
    }

    private func makeFrame(_ hand: VNHumanHandPoseObservation, pixelBuffer: CVPixelBuffer, time: Double) -> HandFrame? {
        guard let recognized = try? hand.recognizedPoints(.all) else { return nil }
        let aspect = Double(CVPixelBufferGetWidth(pixelBuffer)) / Double(CVPixelBufferGetHeight(pixelBuffer))
        let mapping: [(AirDialCore.Joint, VNHumanHandPoseObservation.JointName)] = [
            (.wrist, .wrist), (.thumbCMC, .thumbCMC), (.thumbMP, .thumbMP), (.thumbIP, .thumbIP), (.thumbTip, .thumbTip),
            (.indexMCP, .indexMCP), (.indexPIP, .indexPIP), (.indexDIP, .indexDIP), (.indexTip, .indexTip),
            (.middleMCP, .middleMCP), (.middlePIP, .middlePIP), (.middleDIP, .middleDIP), (.middleTip, .middleTip),
            (.ringMCP, .ringMCP), (.ringPIP, .ringPIP), (.ringDIP, .ringDIP), (.ringTip, .ringTip),
            (.littleMCP, .littleMCP), (.littlePIP, .littlePIP), (.littleDIP, .littleDIP), (.littleTip, .littleTip)
        ]
        var points: [AirDialCore.Joint: Point2] = [:]
        for (joint, name) in mapping {
            guard let point = recognized[name], point.confidence >= 0.3 else { return nil }
            points[joint] = .init((1 - point.location.x) * aspect, 1 - point.location.y)
        }
        let handedness = hand.chirality == .right ? 1 : hand.chirality == .left ? -1 : 0
        return HandClassifier.classify(points, time: time, handedness: handedness)
    }
}
