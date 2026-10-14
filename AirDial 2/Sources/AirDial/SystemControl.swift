import Foundation
import CoreAudio
import Darwin
import AirDialCore

struct SystemVolume {
    private func defaultDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              device != 0 else { return nil }
        return device
    }

    private func address(_ element: UInt32) -> AudioObjectPropertyAddress {
        .init(mSelector: kAudioDevicePropertyVolumeScalar, mScope: kAudioDevicePropertyScopeOutput, mElement: element)
    }

    private func readable(_ device: AudioDeviceID, _ element: UInt32) -> Float32? {
        var property = address(element)
        var value = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectHasProperty(device, &property),
              AudioObjectGetPropertyData(device, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }

    private func writable(_ device: AudioDeviceID, _ element: UInt32) -> Bool {
        var property = address(element)
        var settable = DarwinBoolean(false)
        return AudioObjectIsPropertySettable(device, &property, &settable) == noErr && settable.boolValue
    }

    private func channelCount(_ device: AudioDeviceID) -> UInt32 {
        var property = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &property, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { buffer.deallocate() }
        guard AudioObjectGetPropertyData(device, &property, 0, nil, &size, buffer) == noErr else { return 0 }
        return UnsafeMutableAudioBufferListPointer(buffer.assumingMemoryBound(to: AudioBufferList.self))
            .reduce(0) { $0 + $1.mNumberChannels }
    }

    private func controls(_ device: AudioDeviceID) -> [(UInt32, Float32)] {
        if let master = readable(device, 0), writable(device, 0) { return [(0, master)] }
        let count = channelCount(device)
        guard count > 0, count <= 32 else { return [] }
        var channels: [(UInt32, Float32)] = []
        for channel in 1...count {
            // Do not change only one speaker if the device exposes incomplete controls.
            guard let value = readable(device, channel), writable(device, channel) else { return [] }
            channels.append((channel, value))
        }
        return channels
    }

    func read() -> Double? {
        guard let device = defaultDevice() else { return nil }
        let values = controls(device)
        guard !values.isEmpty else { return nil }
        return values.reduce(0) { $0 + Double($1.1) } / Double(values.count)
    }

    func change(by delta: Double) -> Double? {
        guard let device = defaultDevice() else { return nil }
        let values = controls(device)
        guard !values.isEmpty else { return nil }
        for (channel, current) in values {
            var property = address(channel)
            var value = Float32(min(1, max(0, Double(current) + delta)))
            guard AudioObjectSetPropertyData(device, &property, 0, nil, UInt32(MemoryLayout<Float32>.size), &value) == noErr else { return nil }
        }
        if delta > 0 {
            var mute = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
            var settable = DarwinBoolean(false)
            if AudioObjectIsPropertySettable(device, &mute, &settable) == noErr, settable.boolValue {
                var value = UInt32(0)
                _ = AudioObjectSetPropertyData(device, &mute, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
            }
        }
        return read()
    }
}

/// Private system command bridge, deliberately send-only: no titles, artwork, history, or player data.
/// There is no public macOS API for sending separate Play/Pause commands to the current system player.
/// Dynamically resolve the symbol so an OS change produces a visible failure, not a launch crash.
final class MediaControl {
    private typealias SendCommand = @convention(c) (UInt32, CFDictionary?) -> UInt8
    private var handle: UnsafeMutableRawPointer?
    private var command: SendCommand?
    var available: Bool { command != nil }

    init() {
        handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY | RTLD_LOCAL)
        if let handle, let symbol = dlsym(handle, "MRMediaRemoteSendCommand") {
            command = unsafeBitCast(symbol, to: SendCommand.self)
        }
    }

    deinit { if let handle { dlclose(handle) } }

    func send(_ action: GestureAction) -> Bool {
        let code: UInt32
        switch action {
        case .play: code = 0
        case .pause: code = 1
        case .next: code = 4
        case .previous: code = 5
        default: return false
        }
        // Success means the system accepted dispatch, not that a player completed the action.
        guard let command else { return false }
        return command(code, nil) != 0
    }
}
