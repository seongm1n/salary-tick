// 앱 아이콘 생성기: swift make-icon.swift → AppIcon.icns
// 차콜 스퀘어클 + 민트 진행 호 + 화이트 ₩. build.sh가 자동 호출한다.
import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// macOS 아이콘 여백 규격: 캔버스의 ~10%
let rect = NSRect(x: S * 0.098, y: S * 0.098, width: S * 0.804, height: S * 0.804)
let squircle = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.2237, yRadius: rect.width * 0.2237)

// 그림자
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.012), blur: S * 0.03,
              color: NSColor.black.withAlphaComponent(0.35).cgColor)
NSColor.black.setFill(); squircle.fill()
ctx.restoreGState()

// 패널과 같은 차콜 바탕
squircle.addClip()
NSGradient(colors: [NSColor(srgbRed: 0.13, green: 0.16, blue: 0.18, alpha: 1),
                    NSColor(srgbRed: 0.05, green: 0.07, blue: 0.09, alpha: 1)])!
    .draw(in: rect, angle: -90)

// 패널의 240° 진행 호를 작은 크기에서도 읽히는 심벌로 사용
let center = NSPoint(x: S / 2, y: S / 2)
let radius = S * 0.29
let track = NSBezierPath()
track.appendArc(withCenter: center, radius: radius, startAngle: 210, endAngle: -30, clockwise: true)
track.lineWidth = S * 0.022
track.lineCapStyle = .round
NSColor.white.withAlphaComponent(0.10).setStroke()
track.stroke()
let progress = NSBezierPath()
progress.appendArc(withCenter: center, radius: radius, startAngle: 210, endAngle: 30, clockwise: true)
progress.lineWidth = S * 0.022
progress.lineCapStyle = .round
NSColor(srgbRed: 0.57, green: 0.86, blue: 0.75, alpha: 1).setStroke()
progress.stroke()
let angle = CGFloat.pi / 6
let tip = NSPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: tip.x - S * 0.014, y: tip.y - S * 0.014,
                          width: S * 0.028, height: S * 0.028)).fill()

// ₩
let desc = NSFont.systemFont(ofSize: S * 0.30, weight: .semibold).fontDescriptor
    .withDesign(.default) ?? NSFont.systemFont(ofSize: S * 0.30, weight: .semibold).fontDescriptor
let font = NSFont(descriptor: desc, size: S * 0.30)!
let str = NSAttributedString(string: "₩", attributes: [
    .font: font,
    .foregroundColor: NSColor.white.withAlphaComponent(0.94),
])
let sz = str.size()
str.draw(at: NSPoint(x: rect.midX - sz.width / 2, y: rect.midY - sz.height / 2 + S * 0.012))

img.unlockFocus()

let png = NSBitmapImageRep(data: img.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "build/icon-1024.png"))
print("✅ build/icon-1024.png")
