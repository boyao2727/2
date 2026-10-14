# Privacy / 隐私

## Data flow

```text
Camera video-only input
    → AVCaptureVideoDataOutput (temporary in-memory buffer)
    → Apple Vision hand landmarks
    → numeric pose + gesture state
    → Core Audio volume change OR send-only media command
    → discard temporary frames
```

The capture queue processes at most 20 frames per second. Unprocessed late frames are dropped. No frame is copied to disk, shown in a saved preview, or included in diagnostics. Application state stores numeric progress and the last command only in memory. There is no telemetry, updater, web view, network client, movie/photo output, audio input, screen capture, file browser, or Photos integration.

## Permission inventory

| Resource | Implementation |
|---|---|
| Camera | Requested via AVFoundation, required to recognize gestures |
| Microphone | Never requested; no audio capture input |
| Photos | Never requested; no Photos API |
| Files / folders | No access to personal files; app resources and preferences only |
| Accessibility | Never requested; no keyboard injection or UI inspection |
| Automation | Never requested; no Apple Events or scripts |
| Screen recording | Never requested |
| Network | No networking code or dependencies |

`Resources/Info.plist` declares only `NSCameraUsageDescription`. `Resources/AirDial.entitlements` contains only `com.apple.security.device.camera` for Developer ID hardened-runtime use. The app is **not App Sandbox enabled**. These are implementation restrictions, not a sandbox guarantee preventing all possible file/network operations by a modified binary. Auditing the source and verifying the download remain relevant.

## Persistence

`UserDefaults` stores only `enableOnLaunch` and `language`. The app does not store images, video, joint coordinates, calibration data, playback history, player metadata, or identifying analytics. macOS may independently keep authorization records and framework/system diagnostics.

## Shutdown

Turning control off invalidates pending authorization and recognition callbacks immediately, stops capture on the serial camera queue, removes capture inputs and outputs, and resets numeric tracking state. In-flight processing may take a short time to finish; the camera indicator goes out after the session stops. Quitting synchronously drains and closes the camera session. Sleep stops the camera; wake restarts only if control was active before sleep.

## 中文说明

画面仅在本机内存中处理，应用不保存、上传或记录画面，不访问用户文件、相册、麦克风或屏幕。只请求摄像头权限；不会请求辅助功能或自动化权限。只保存启停偏好和语言两个设置。关闭控制立即停止接受手势指令，当前处理结束后释放摄像头。系统自身仍会保留权限记录等系统数据。当前应用未启用 App Sandbox，因此上述边界由实现保证，不等同于操作系统强制阻断一切文件或网络访问。
