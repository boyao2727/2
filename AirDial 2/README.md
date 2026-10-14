# AirDial

**用手势控制 Mac 的音量和媒体播放。 / Control your Mac’s volume and media with hand gestures.**

原生 macOS 菜单栏应用，提供简体中文与美式英语。无需 Python、浏览器、云服务或额外模型下载。

Native macOS menu bar app in Simplified Chinese and US English. No Python, browser, cloud service, or model download required.

> **0.1.0 beta**：已实现手势规则、菜单栏、双语及应用打包。识别器使用 Apple Vision 的二维关键点与几何规则，真实摄像头效果需要实测校准；不能保证准确判断所有朝向或覆盖所有播放器。详见 [已知限制](docs/LIMITATIONS.md)。
>
> **0.1.0 beta**: Gesture rules, menu bar, localization, and packaging are implemented. Recognition uses Apple Vision 2D landmarks and geometric heuristics. Real-camera accuracy needs calibration; exact orientation and all-player support are not guaranteed. See [limitations](docs/LIMITATIONS.md).

## 下载与运行 / Download and run

要求 macOS 13 或更新版本，配有可用摄像头。Universal 构建同时支持 Apple Silicon 与 Intel。

Requires macOS 13+ and a working camera. Universal builds support both Apple Silicon and Intel.

1. 在 GitHub 仓库的 **Releases** 中下载 `AirDial-版本-universal.zip`。首次发布前可从源码构建。
2. 解压，将 `AirDial.app` 拖入“应用程序”，打开后在顶部菜单栏找到手形图标。
3. 首次启用时允许摄像头访问。没有主窗口；点击菜单栏中的“功能指引”查看操作说明。
4. 应用首次默认开启控制。关闭“默认开启”后，菜单显示“开启控制 / 关闭控制”。应用记住此偏好；手动模式下下次启动先关闭。
5. 通过“语言”选择“简体中文”或“English (US)”。切换立即生效并保存。

1. Download `AirDial-version-universal.zip` from the repository’s **Releases**. Build from source before the first release exists.
2. Unzip, move `AirDial.app` to Applications, and open it. Find the hand icon in the menu bar.
3. Allow camera access on first use. Open **Gesture Guide** from the menu; there is no main window.
4. **Enable on Launch** is on by default. Turning it off shows **Enable / Disable Gesture Control**. The preference is saved; manual mode starts off at the next launch.
5. Choose **简体中文** or **English (US)** from **Language**. Changes apply immediately and persist.

### 测试版签名 / Beta signing

本地脚本和默认 GitHub 工作流生成 **ad-hoc 签名、未经 Apple 公证** 的测试版。它不等同于可免提示安装的正式发行版。下载的测试版可能被 Gatekeeper 拦截；请核对来源，仅对你信任的构建使用系统设置中单独允许该应用的功能。无需关闭 Gatekeeper 或 SIP。正式公开分发建议使用 Developer ID 签名及公证，见下文。

Local builds and default GitHub workflows produce **ad-hoc signed, non-notarized** beta apps. Gatekeeper may block downloaded builds. Verify the source and allow only a build you trust using the per-app system setting; do not disable Gatekeeper or SIP. Use Developer ID signing and notarization for normal public distribution.

## 手势 / Gestures

所有方向均以用户视角为准。只用一只手，保持整只手入镜及良好光线。检测到多只手或关键点不可靠时不发送指令。

All directions are from your view. Use one hand, keep it fully visible, and use good lighting. Multiple hands or unreliable landmarks suppress commands.

| 功能 / Action | 手势 / Gesture |
|---|---|
| 音量 +5 个百分点 / Volume +5 percentage points | 指尖朝屏幕，顺时针完整转一圈 / Point at screen, complete a clockwise turn |
| 音量 −5 个百分点 / Volume −5 percentage points | 指尖朝屏幕，逆时针完整转一圈 / Point at screen, complete a counterclockwise turn |
| 下一个 / Next | 手掌侧面对摄像头，向右扫 / Palm edge-on, swipe right |
| 上一个 / Previous | 手掌侧面对摄像头，向左扫 / Palm edge-on, swipe left |
| 暂停 / Pause | 张开掌心朝屏幕保持片刻，再握拳约半秒 / Open palm toward screen briefly, then hold a fist for about half a second |
| 播放 / Play | 竖起大拇指约半秒 / Hold a thumbs-up for about half a second |

调节音量时只伸食指，或伸出并拢的食指和中指，其余手指收起。圆的平面应平行于屏幕。支持指尖轨迹和手腕姿态旋转两条识别路径；一次动作只计数一次。转圈不足一圈不调节；手离开、换手形或识别中断会清除未完成的进度。播放、暂停使用两个独立指令，绝不以切换播放状态替代。

For volume, extend only your index finger, or index and middle fingers together, curling the rest. Keep the circle parallel to the screen. A fingertip path and wrist-pose rotation are separate detection paths; one motion is never counted twice. Partial turns do not change volume. Losing the hand, changing pose, or an interrupted observation clears partial progress. Play and Pause are separate commands, never a toggle.

## 隐私 / Privacy

- 实时视频帧只在本机、内存中进入 Apple Vision，处理后释放。没有拍照、录像、预览保存或上传功能。
- 不配置麦克风、相册、屏幕录制、网络访问或分析服务；不读取用户文件。
- 关闭控制时停止采集并移除摄像头输入。退出时等待摄像头处理队列清理完成。
- 只保存两个偏好：默认开启状态及界面语言。不保存手势轨迹或媒体信息。
- 媒体桥接只发送播放、暂停、上一首和下一首；不读取媒体标题、封面、播放历史或播放器数据。
- 摄像头权限是唯一请求的隐私权限。当前构建不请求辅助功能或自动化权限。
- 当前采用非 App Sandbox 应用及摄像头 entitlement；没有沙箱层的文件或网络禁止保证。隐私边界来自源码中的实现与权限请求范围，可审计。

Live frames are processed locally in memory by Apple Vision and then released. No photo, recording, saved preview, upload, microphone, Photos, screen recording, telemetry, or user-file access is implemented. Disabling control stops capture and removes camera inputs; quitting waits for cleanup. Only launch and language preferences persist. Media control is send-only, with no titles, artwork, history, or player data. Camera is the only requested privacy permission. This is a non-App-Sandbox build; privacy is an auditable implementation boundary, not a sandbox-enforced ban on file/network access.

See [PRIVACY.md](docs/PRIVACY.md) for the source-level inventory.

## 从源码构建 / Build from source

安装 Xcode Command Line Tools 或 Xcode（Swift 5.9+）。项目没有第三方依赖，不需要下载识别模型。

Install Xcode Command Line Tools or Xcode with Swift 5.9+. There are no third-party dependencies or model downloads.

```bash
swift run AirDialChecks
bash scripts/build.sh universal
open dist/AirDial.app
```

Apple Silicon 本机构建可用 `bash scripts/build.sh arm64`；Intel 构建可用 `bash scripts/build.sh x86_64`。请运行 `.app`，而非 `swift run`，使摄像头权限正确绑定到应用。

Use `bash scripts/build.sh arm64` or `bash scripts/build.sh x86_64` for an architecture-specific app. Run the `.app` rather than `swift run` so camera authorization is associated with the app bundle.

```bash
# 只检查安装，不开启摄像头、不改变音量、不发送媒体指令
# Installation diagnostic only: no capture, volume changes, or media commands
dist/AirDial.app/Contents/MacOS/AirDial --self-check

# 只查看指引窗口，不开启摄像头 / Preview the guide without activating camera
open dist/AirDial.app --args --preview-guide
```

可以用 Xcode 直接打开 `Package.swift` 编辑源码。部署目标为 macOS 13。核心识别状态机与系统副作用分离，测试无需摄像头或播放器。

Open `Package.swift` in Xcode to edit. Deployment target is macOS 13. The recognition state machine is separate from system effects, so tests require no camera or player.

## 发布到 GitHub / Publish to GitHub

仓库已包含 CI 和 Release 工作流。源码上传到你创建的 GitHub 仓库后：

1. 每次推送运行测试并生成 universal 应用下载附件。
2. 推送形如 `v0.1.0-beta` 的标签，自动建立预发布版本并附上 ZIP 及 SHA-256。
3. 默认工作流不包含签名证书或密钥，也不会生成 Apple 公证版。

The repository includes CI and Release workflows. After uploading the source to your GitHub repository, pushes run tests and build a universal artifact. Pushing a tag such as `v0.1.0-beta` creates a prerelease with ZIP and SHA-256 files. Default workflows contain no signing secrets and do not notarize the app.

正式签名和公证 / Developer ID signing and notarization:

```bash
# 先将 Developer ID 证书安装到 Keychain，并用 notarytool 保存凭据
# Install a Developer ID certificate and store a notarytool Keychain profile first
export AIRDIAL_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export AIRDIAL_NOTARY_PROFILE='your-notary-profile'
bash scripts/notarize.sh universal
```

## 目录 / Layout

| 路径 / Path | 内容 / Contents |
|---|---|
| `Sources/AirDialCore` | 手形分类、转圈计数、手势状态机、偏好 / Pose classification, rotation tracking, gesture state machine, preferences |
| `Sources/AirDial` | 摄像头、系统音量、媒体桥接、菜单栏与双语指引 / Camera, volume, media bridge, menu bar, localized guide |
| `Tests` | 不访问硬件的行为测试 / Hardware-free behavioral tests |
| `Resources` | 应用信息、摄像头授权文案、签名 entitlement / App metadata, camera strings, signing entitlement |
| `scripts` | Universal 打包、签名、公证 / Universal packaging, signing, notarization |

## 技术参考 / References

- [Apple Vision hand pose detection](https://developer.apple.com/documentation/vision/vndetecthumanhandposerequest)
- [Apple camera privacy declaration](https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription)
- [Apple remote command receiving model](https://developer.apple.com/documentation/mediaplayer/handling-external-player-events-notifications)
- [GitHub hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)

MIT License.
