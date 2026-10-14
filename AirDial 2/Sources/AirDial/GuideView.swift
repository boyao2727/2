import SwiftUI

struct GuideView: View {
    @ObservedObject var model: AppModel
    private let accent = Color(red: 0.19, green: 0.64, blue: 0.53)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 14) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 32)).foregroundStyle(accent)
                        .frame(width: 62, height: 62).background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AirDial").font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(model.text(.subtitle)).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label(model.text(model.status), systemImage: model.enabled ? "circle.fill" : "circle")
                        .font(.caption).foregroundStyle(model.enabled ? accent : .secondary)
                }
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(accent.opacity(0.13), lineWidth: 6)
                        Circle().trim(from: 0, to: model.progress).stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .scaleEffect(x: model.direction < 0 ? -1 : 1, y: 1)
                        Image(systemName: model.direction < 0 ? "arrow.counterclockwise" : "arrow.clockwise")
                            .font(.system(size: 24, weight: .medium)).foregroundStyle(accent)
                    }.frame(width: 62, height: 62)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.text(.turnProgress)).font(.caption).foregroundStyle(.secondary)
                        Text("\(Int(model.progress * 100))%").font(.title3.monospacedDigit().bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(model.text(.volume)).font(.caption).foregroundStyle(.secondary)
                        Text(model.volume.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                            .font(.title3.monospacedDigit().bold())
                    }
                }.padding(18).background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 14) {
                    Text(model.text(.controls)).font(.headline)
                    gesture("arrow.clockwise", title: .clockwise, second: .counterclockwise, body: .volumeHint)
                    gesture("arrow.left.arrow.right", title: .next, second: .previous, body: .swipeHint)
                    gesture("hand.raised.fill", title: .pause, body: .pauseHint)
                    gesture("hand.thumbsup.fill", title: .play, body: .playHint)
                }
                if let notice = model.notice {
                    Label(model.text(notice), systemImage: "exclamationmark.circle")
                        .font(.callout).foregroundStyle(.orange)
                }
                HStack {
                    Text(model.text(.latest)).foregroundStyle(.secondary)
                    Spacer()
                    Text(model.lastAction.map { model.text($0.textKey) } ?? model.text(.waiting))
                }.font(.caption)
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.text(.privacyTitle), systemImage: "lock.shield").font(.headline)
                    Text(model.text(.privacy)).font(.callout).foregroundStyle(.secondary)
                    Text(model.text(.permissions)).font(.caption).foregroundStyle(.secondary)
                    Text(model.text(.compatibility)).font(.caption).foregroundStyle(.secondary)
                }
            }.padding(28)
        }
        .frame(minWidth: 640, idealWidth: 660, minHeight: 590, idealHeight: 740)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func gesture(_ icon: String, title: TextKey, second: TextKey? = nil, body: TextKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 21)).foregroundStyle(accent)
                .frame(width: 38, height: 38).background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(model.text(title)).fontWeight(.semibold)
                    if let second { Text("/ " + model.text(second)).foregroundStyle(.secondary) }
                }.font(.callout)
                Text(model.text(body)).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
