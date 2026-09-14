// 앱 아이콘 생성기: swift make-icon.swift → AppIcon.icns
// 민트→시안 스퀘어클 + 차콜 ₩. build.sh가 자동 호출한다.
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

// 민트 → 시안
squircle.addClip()
NSGradient(colors: [NSColor(srgbRed: 0.53, green: 0.96, blue: 0.68, alpha: 1),
                    NSColor(srgbRed: 0.29, green: 0.85, blue: 0.90, alpha: 1)])!
    .draw(in: rect, angle: -60)

// 상단 하이라이트로 살짝 입체감
NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
    .draw(in: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)

// ₩
let desc = NSFont.systemFont(ofSize: S * 0.46, weight: .semibold).fontDescriptor
    .withDesign(.rounded) ?? NSFont.systemFont(ofSize: S * 0.46, weight: .semibold).fontDescriptor
let font = NSFont(descriptor: desc, size: S * 0.46)!
let str = NSAttributedString(string: "₩", attributes: [
    .font: font,
    .foregroundColor: NSColor(srgbRed: 0.05, green: 0.11, blue: 0.13, alpha: 0.92),
])
let sz = str.size()
str.draw(at: NSPoint(x: rect.midX - sz.width / 2, y: rect.midY - sz.height / 2 + S * 0.012))

img.unlockFocus()

let png = NSBitmapImageRep(data: img.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "build/icon-1024.png"))
print("✅ build/icon-1024.png")
