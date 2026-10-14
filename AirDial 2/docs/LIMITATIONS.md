# 已知限制 / Known limitations

This beta is a working implementation, not a claim of validated real-world recognition accuracy.

## 摄像头方向与手腕旋转 / Orientation and wrist rotation

Apple Vision provides 2D hand joints. With one ordinary webcam, the application does **not** measure true depth or reconstruct a physical 3D finger axis. It uses projected finger length, straightness, palm width, chirality, and thumb position as conservative approximations. A finger aimed directly at the lens can occlude its own joints. Some bent fingers can look like a forward-pointing finger. Palm versus back-of-hand estimates can fail under roll, occlusion, or handedness errors.

Circle paths are fit geometrically, and long finger projections toward the ceiling or sides are rejected. This helps enforce the intended plane but cannot prove a 3D circle is parallel to the screen. Wrist-only rotation is an experimental thumb-around-index angle proxy. Wrist motion has a limited physical range, and a complete 360° turn may be impractical. Partial turns are not volume commands; they cancel when tracking or hand pose is lost. Clear fingertip circles are the most practical beta input. No webcam samples have been collected or saved during development.

单个普通摄像头无法可靠测量手指的真实三维朝向。本版用投影长度、直线度、掌宽、左右手和拇指位置做近似判断，不能保证所有“指向屏幕”的动作都识别，也不能保证排除所有错误方向。指尖正对镜头、侧掌遮挡、光线差时尤其困难。原地手腕旋转是实验性识别，身体可旋转角度也有限，完成整圈可能不方便。测试版建议优先画明显的指尖圆；不足一圈不改变音量。

A future stronger recognizer would require a calibrated, permissioned real-camera evaluation set, better orientation estimation, and potentially a dedicated temporal model. It must retain local-only processing.

## 媒体控制 / Media control

The send-only bridge dynamically resolves Apple's **private** `MRMediaRemoteSendCommand` from the system MediaRemote framework. Values 0/1/4/5 correspond to Play/Pause/Next/Previous. It never reads Now Playing data or uses playback toggles. There is no public system-wide macOS API with these separate outgoing commands; `MPRemoteCommandCenter` is for receiving commands in the playing app.

This API is undocumented and may change or fail on a macOS update. The function's return value indicates dispatch, not player acknowledgement. Receiving apps can ignore commands, and a paused player may no longer be the current system target. Multiple players are routed by macOS, not selected by AirDial. Previous may restart the current track according to the player's rules. A failed symbol lookup or rejected dispatch is surfaced in Gesture Guide. No private entitlement, SIP bypass, Perl-host workaround, Accessibility grant, or AppleScript automation is used.

媒体指令使用系统私有接口，可能随 macOS 更新失效。返回成功只表示系统接受发送，不代表播放器执行完成。播放器是否支持上下首、暂停后是否仍是系统控制目标，以及“上一首”是否先回到本首开头，都由系统和播放器决定。本版没有绕过系统保护、申请私有 entitlement 或用播放状态切换模拟独立播放/暂停。需要逐个播放器实测；不承诺所有浏览器或播放器都兼容。该桥接不适用于 Mac App Store 发布。

## 系统音量 / System volume

Core Audio changes the default output device's scalar volume by 0.05 per turn, clamped to 0…1. This is five percentage points of the slider, not a perceptually uniform loudness increase. Master volume is preferred; otherwise complete writable output-channel controls are used while preserving their level differences until clamping. HDMI, DisplayPort, some USB interfaces, and digital outputs can have no writable system volume; the app reports this and does not change a player's internal volume as a substitute. Output device changes are handled by resolving the current default device on each command.

部分 HDMI、显示器或音频接口不支持系统音量调节，应用会提示。它控制系统输出音量，不改变单个播放器内部的音量设置。

## 发布与验证 / Distribution and verification

The default app is ad-hoc signed, not Developer ID signed or notarized. Downloaded builds may be blocked by Gatekeeper. Camera privacy identity may need reauthorization when an ad-hoc binary changes. Developer ID signing and Apple notarization are separate release steps requiring the publisher's credentials. macOS 13 is the deployment target; older OS versions and Intel runtime behavior require device testing even when cross-compilation succeeds. See VALIDATION.md for checks actually performed.
