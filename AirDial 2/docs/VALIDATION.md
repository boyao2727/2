# Verification record / 验证记录

Date: 2026-10-14. Version: 0.1.0-beta.

## Completed

- Release compilation for both arm64 and x86_64, deployment target macOS 13.
- Universal Mach-O binary verified with `lipo`.
- 18 hardware-free behavioral checks passed with zero assertion failures: clockwise/counterclockwise full turns; partial turns; straight paths and jitter; elongated ellipses; wrist-angle integration; rotation deduplication; hand switching and frame gaps; right/left swipes; vertical-motion rejection; swipe cooldown including tracking loss; palm-to-fist arming; thumbs-up hold/latch; tracking reset; persistent settings and language selection; forward-finger projection versus upward/sideways projections; joined-finger gate; fist/thumb separation; missing/small-hand rejection.
- Application and localization property-list syntax validated.
- Build/notarization script syntax validated.
- Download ZIP unpacked into a fresh temporary directory and its ad-hoc code signature verified.
- ARM installation diagnostic ran successfully without camera access or media/volume changes. The MediaRemote send symbol was found. The execution environment exposed no writable system-output volume control.
- Source inventory inspected for photo/movie output, microphone capture, Photos APIs, personal-file access, networking, keyboard injection, and AppleScript. None is implemented.

## Not completed / limitations of this record

- **Visual UI verification did not complete.** The desktop UI tool timed out. Launching from the command execution environment failed during macOS AppKit application registration (`NSApplication` initialization), before the app delegate ran. This does not establish successful normal desktop launch. Menu layout, live language switching, and the guide window still need a real desktop test.
- No live webcam accuracy measurement, orientation validation, physical wrist-rotation trial, camera-permission flow, or camera-indicator shutdown test was performed.
- No actual system-volume change was tested; the execution environment has no writable output volume.
- No command was sent to a real media player. Symbol availability does not establish playback compatibility or receipt.
- Intel hardware runtime and macOS 13/14 runtime are untested. Cross-compilation is not a substitute for these checks. The local toolchain emitted an x86_64 warning about an unused arm64-only Swift compatibility archive; linking succeeded.
- GitHub workflows have been prepared but not run on GitHub. No remote repository or release has been created in this chat.
- No Developer ID signature or Apple notarization was performed. Publisher credentials are required for those release steps.

The source and beta ZIP are delivered for review and hands-on testing. They should not be described as production-ready or as having validated recognition accuracy.

## 中文

已完成双架构编译、18 项不访问硬件的行为检查、应用信息和脚本格式检查、ZIP 解压后的签名校验，以及不操作摄像头或媒体的安装诊断。

桌面预览工具超时，执行环境也无法完成 AppKit 的桌面应用注册，因此**尚未确认实际桌面启动及界面效果**。真实摄像头识别、摄像头关闭指示灯、原地手腕旋转、设备音量、各播放器、Intel 实机及旧版 macOS 均需要进一步实测。媒体私有接口只确认了发送符号存在，尚未验证播放器响应。GitHub 工作流尚未在线运行；测试包未经 Apple 公证。
