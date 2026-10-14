import Foundation
import AirDialCore

enum TextKey {
    case subtitle, launch, enable, disable, guide, language, quit, active, inactive, starting
    case cameraDenied, cameraMissing, cameraFailed, visionFailed, volumeUnavailable, mediaUnavailable
    case privacy, clockwise, counterclockwise, next, previous, pause, play, volumeHint, swipeHint
    case pauseHint, playHint, permissionTitle, permissionBody, settings, done, latest, waiting
    case volume, turnProgress, controls, privacyTitle, permissions, compatibility
}

func localized(_ key: TextKey, _ language: AppLanguage) -> String {
    let pair: (String, String)
    switch key {
    case .subtitle: pair = ("用手势，掌控声音。", "Your hand. Your sound.")
    case .launch: pair = ("默认开启", "Enable on Launch")
    case .enable: pair = ("开启控制", "Enable Gesture Control")
    case .disable: pair = ("关闭控制", "Disable Gesture Control")
    case .guide: pair = ("功能指引", "Gesture Guide")
    case .language: pair = ("语言", "Language")
    case .quit: pair = ("退出应用", "Quit AirDial")
    case .active: pair = ("手势控制已开启", "Gesture control is on")
    case .inactive: pair = ("手势控制已关闭", "Gesture control is off")
    case .starting: pair = ("正在启动摄像头…", "Starting camera…")
    case .cameraDenied: pair = ("摄像头权限未开启", "Camera access is not enabled")
    case .cameraMissing: pair = ("未找到可用的摄像头", "No available camera found")
    case .cameraFailed: pair = ("摄像头不可用，请关闭控制后重试", "Camera unavailable. Turn control off and try again.")
    case .visionFailed: pair = ("手势识别暂时不可用", "Hand recognition is temporarily unavailable")
    case .volumeUnavailable: pair = ("当前输出设备不支持系统音量调节", "This output device has no system volume control")
    case .mediaUnavailable: pair = ("媒体指令未能发送，请在播放器中操作", "Media command could not be sent. Use your player.")
    case .privacy: pair = ("实时画面仅在本机用于手势识别。不拍照、不录像、不保存或上传画面；不访问相册、用户文件或麦克风。关闭控制即释放摄像头。", "Live frames are processed only on your Mac. No photos, recordings, saved frames, uploads, or access to Photos, personal files, or your microphone. Turning control off releases the camera.")
    case .clockwise: pair = ("顺时针 · 音量 +5%", "Clockwise · Volume +5%")
    case .counterclockwise: pair = ("逆时针 · 音量 −5%", "Counterclockwise · Volume −5%")
    case .next: pair = ("向右扫 · 下一个媒体", "Swipe right · Next media")
    case .previous: pair = ("向左扫 · 上一个媒体", "Swipe left · Previous media")
    case .pause: pair = ("握拳 · 暂停", "Close your fist · Pause")
    case .play: pair = ("竖起大拇指 · 播放", "Thumbs up · Play")
    case .volumeHint: pair = ("伸出食指，或并拢食指和中指，指尖朝屏幕。在平行于屏幕的平面内画圈，也可用手腕带动旋转。每完整一圈调节 5 个百分点；方向以用户视角为准。其余手指收起。", "Point your index finger, or your index and middle fingers together, toward the screen. Draw a circle parallel to the screen, or rotate from your wrist. Each full turn changes volume by 5 percentage points. Directions are from your view. Curl the remaining fingers.")
    case .swipeHint: pair = ("手掌侧面对着摄像头，明显地水平扫动。向右是下一个，向左是上一个。切换后有 1 秒间隔。", "Hold your palm edge-on to the camera and swipe horizontally. Right goes next; left goes previous. A 1-second cooldown prevents repeats.")
    case .pauseHint: pair = ("先将张开的掌心朝向屏幕，保持片刻，再握拳约半秒。只发送暂停指令。", "Face your open palm toward the screen briefly, then hold a fist for about half a second. Sends Pause only.")
    case .playHint: pair = ("其余四指收起，竖起大拇指并保持约半秒。只发送播放指令，持续保持不会重复触发。", "Curl the other four fingers, raise your thumb, and hold for about half a second. Sends Play only, once per hold.")
    case .permissionTitle: pair = ("允许摄像头用于手势识别", "Allow camera access for gestures")
    case .permissionBody: pair = ("AirDial 需要读取实时画面才能识别手势。请在“系统设置 → 隐私与安全性 → 摄像头”中允许 AirDial，然后重启应用。", "AirDial needs live camera frames to recognize gestures. Allow AirDial in System Settings → Privacy & Security → Camera, then restart the app.")
    case .settings: pair = ("打开系统设置", "Open System Settings")
    case .done: pair = ("完成", "Done")
    case .latest: pair = ("最近操作", "Last command")
    case .waiting: pair = ("等待手势", "Waiting for a gesture")
    case .volume: pair = ("系统音量", "System volume")
    case .turnProgress: pair = ("本圈进度", "Current turn")
    case .controls: pair = ("手势操作", "Gestures")
    case .privacyTitle: pair = ("只在你的 Mac 上", "Only on your Mac")
    case .permissions: pair = ("首次启用需要摄像头权限，无需麦克风、相册或辅助功能权限。语言切换立即生效。", "Camera permission is needed on first use. No microphone, Photos, or Accessibility permission is requested. Language changes take effect immediately.")
    case .compatibility: pair = ("单摄像头的朝向判断是近似值。手腕原地旋转和指尖正对镜头时可能难以识别；画明显的圆更容易成功。媒体指令由系统当前媒体播放器处理，兼容性取决于播放器及 macOS 版本。", "Direction estimates from one camera are approximate. Wrist-only turns and fingers aimed directly at the lens may be hard to detect; clear circular paths are easier. The system’s current media player handles commands; support depends on the player and macOS version.")
    }
    return language == .chinese ? pair.0 : pair.1
}

extension GestureAction {
    var textKey: TextKey {
        switch self {
        case .volumeUp: return .clockwise
        case .volumeDown: return .counterclockwise
        case .next: return .next
        case .previous: return .previous
        case .pause: return .pause
        case .play: return .play
        }
    }
}
