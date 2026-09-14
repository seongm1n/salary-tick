import SwiftUI
import ServiceManagement

// MARK: - 계산 (순수 함수. 검증: ./build.sh test)

enum Pay {
    /// 초당 수입. 하루근무초 = (퇴근-출근)*3600
    static func perSecond(annual: Int, start: Double, end: Double, workdays: Int) -> Double {
        let daySeconds = (end - start) * 3600
        guard daySeconds > 0, workdays > 0, annual > 0 else { return 0 }
        return Double(annual) / (Double(workdays) * daySeconds)
    }

    /// 출근~현재 경과초 (출근 전 0, 퇴근 후 하루치로 고정)
    static func elapsed(now: Double, start: Double, end: Double) -> Double {
        min(max(now - start, 0), max(end - start, 0))
    }

    static func earned(annual: Int, start: Double, end: Double, workdays: Int, nowHour: Double) -> Double {
        perSecond(annual: annual, start: start, end: end, workdays: workdays)
            * elapsed(now: nowHour * 3600, start: start * 3600, end: end * 3600)
    }

    static func progress(start: Double, end: Double, nowHour: Double) -> Double {
        let span = (end - start) * 3600
        guard span > 0 else { return 0 }
        return elapsed(now: nowHour * 3600, start: start * 3600, end: end * 3600) / span
    }

    /// 이번 달/올해의 근무일 수. done은 오늘 이전까지(오늘 제외).
    /// ponytail: 달력을 하루씩 훑는다(최대 366회/틱). 프로파일에 잡히면 날짜 키로 캐시.
    static func workdays(scope: Scope, now: Date, cal: Calendar = .current) -> (done: Double, total: Double) {
        guard let span = cal.dateInterval(of: scope == .month ? .month : .year, for: now) else { return (0, 1) }
        let today = cal.startOfDay(for: now)
        var d = span.start, done = 0.0, total = 0.0
        while d < span.end {
            if !cal.isDateInWeekend(d) {
                total += 1
                if d < today { done += 1 }
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return (done, total)
    }

    /// 기간 진행률 = (지난 근무일 + 오늘 몫) / 전체 근무일
    static func periodProgress(scope: Scope, now: Date, dayProgress: Double, cal: Calendar = .current) -> Double {
        let w = workdays(scope: scope, now: now, cal: cal)
        guard w.total > 0 else { return 0 }
        let todayShare = cal.isDateInWeekend(now) ? 0 : dayProgress
        return min((w.done + todayShare) / w.total, 1)
    }
}

/// 메뉴바 라벨과 패널이 같이 보는 기간. 원문이 그대로 UI 라벨이다.
enum Scope: String, CaseIterable, Identifiable {
    case day = "오늘", month = "이번 달", year = "올해"
    var id: String { rawValue }
}

// MARK: - 상태

/// 1초마다 now를 흘려보내는 공용 시계. 메뉴바 라벨과 패널이 같은 걸 본다.
final class Clock: ObservableObject {
    @Published var now = Date()
    init() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.now = Date() }
        RunLoop.main.add(t, forMode: .common)  // 메뉴 열려 있어도 계속 돈다
    }
}

/// 자정 기준 경과 시간(시 단위). 9시 30분 → 9.5
extension Date {
    var hourOfDay: Double {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        return Double(c.hour!) + Double(c.minute!) / 60 + Double(c.second!) / 3600
    }
}

/// 설정값 4개. 메뉴바 라벨과 패널이 똑같이 읽어야 해서 한 군데로 묶는다.
struct Config {
    @AppStorage("annualSalary") var annual = 50_000_000
    @AppStorage("startHour") var start = 9.0
    @AppStorage("endHour") var end = 18.0
    @AppStorage("workdaysPerYear") var workdays = 250
    @AppStorage("scope") var scope = Scope.day

    /// 선택한 기간을 꽉 채웠을 때의 금액
    var total: Double {
        switch scope {
        case .day:   return perSecond * (end - start) * 3600
        case .month: return Double(annual) / 12
        case .year:  return Double(annual)
        }
    }
    func earned(_ now: Date) -> Double { total * progress(now) }

    func progress(_ now: Date) -> Double {
        let day = Pay.progress(start: start, end: end, nowHour: now.hourOfDay)
        return scope == .day ? day : Pay.periodProgress(scope: scope, now: now, dayProgress: day)
    }
    var perSecond: Double {
        Pay.perSecond(annual: annual, start: start, end: end, workdays: workdays)
    }
}

// MARK: - 디자인 토큰 (README.md § 디자인)

enum Ink {
    static let mint = Color(red: 0.53, green: 0.96, blue: 0.68)
    static let cyan = Color(red: 0.29, green: 0.85, blue: 0.90)
    static let money = LinearGradient(colors: [mint, cyan], startPoint: .leading, endPoint: .trailing)
    static let gauge = AngularGradient(colors: [mint, cyan, mint],
                                       center: .center, angle: .degrees(140))
    /// 패널 전체 배경. 기본 머티리얼 대신 어두운 판을 깔아야 민트가 산다.
    static let panel = LinearGradient(
        colors: [Color(red: 0.09, green: 0.11, blue: 0.13),
                 Color(red: 0.05, green: 0.06, blue: 0.08)],
        startPoint: .top, endPoint: .bottom)
    static let dim = Color.white.opacity(0.42)
}

private let won = Decimal.FormatStyle.Currency(code: "KRW", locale: Locale(identifier: "ko_KR"))
private func money(_ v: Double, _ digits: Int = 0) -> String {
    Decimal(v).formatted(won.precision(.fractionLength(digits)))
}

// MARK: - 게이지

/// 아래가 트인 240° 타코미터 호. t는 0...1
struct Arc: Shape {
    var from = 0.0, to = 1.0
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY),
                 radius: min(r.width, r.height) / 2,
                 startAngle: .degrees(150 + 240 * from),
                 endAngle: .degrees(150 + 240 * to),
                 clockwise: false)
        return p
    }
}

struct Gauge: View {
    let title: String
    let progress: Double
    let amount: Double
    let caption: String
    let from: String, to: String
    var glow: Double = 0

    /// 채워진 호 끝점 좌표 — 여기에 빛나는 점을 얹는다
    private func tip(in size: CGFloat) -> CGPoint {
        let a = (150 + 240 * progress) * .pi / 180
        let r = size / 2 - 11
        return CGPoint(x: size / 2 + cos(a) * r, y: size / 2 + sin(a) * r)
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Arc().stroke(Color.white.opacity(0.07), style: .init(lineWidth: 10, lineCap: .round))
                    .padding(11)

                // 눈금 40개. 지나간 눈금만 밝다.
                ForEach(0..<41) { i in
                    let t = Double(i) / 40
                    Capsule()
                        .fill(t <= progress ? Ink.mint.opacity(0.5) : Color.white.opacity(0.09))
                        .frame(width: 1.5, height: t.truncatingRemainder(dividingBy: 0.25) < 0.01 ? 7 : 4)
                        .offset(y: -s / 2 + 26)
                        .rotationEffect(.degrees(240 * t - 120))
                }

                Arc(to: max(progress, 0.0001))
                    .stroke(Ink.gauge, style: .init(lineWidth: 10, lineCap: .round))
                    .padding(11)
                    .shadow(color: Ink.mint.opacity(0.55 + glow), radius: 10 + glow * 14)

                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .shadow(color: Ink.cyan.opacity(0.9), radius: 6)
                    .position(tip(in: s))
                    .opacity(progress > 0.002 ? 1 : 0)

                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Ink.dim)
                        .textCase(.uppercase).tracking(1.2)
                    Text(money(amount))
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Ink.money)
                        .contentTransition(.numericText(value: amount))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .shadow(color: Ink.mint.opacity(0.25 + glow * 0.6), radius: 12 + glow * 10)
                        .padding(.horizontal, 44)
                    Text(caption)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }

                // 게이지가 트인 자리에 출·퇴근 시각을 얹는다
                HStack {
                    Text(from); Spacer(); Text(to)
                }
                .font(.system(size: 11, weight: .semibold)).monospacedDigit()
                .foregroundStyle(Ink.dim)
                .frame(width: s * 0.80)
                .offset(y: s * 0.35)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - 앱

private let previewMode = CommandLine.arguments.contains("--preview")

@main
struct SalaryTickApp: App {
    @StateObject private var clock = Clock()

    init() {
        if CommandLine.arguments.contains("--selftest") { selfTest(); exit(0) }
        if previewMode { renderPreview(); exit(0) }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView().environmentObject(clock)
        } label: {
            MenuLabel().environmentObject(clock)
        }
        .menuBarExtraStyle(.window)
    }
}

/// 디자인 확인용. 패널을 오프스크린 렌더해서 PNG로 떨군다. 화면 녹화 권한 불필요.
@MainActor func renderPreview() {
    let r = ImageRenderer(content: PanelView().environmentObject(Clock()))
    r.scale = 2
    guard let img = r.nsImage, let tiff = img.tiffRepresentation,
          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    else { print("render 실패"); return }
    try? png.write(to: URL(fileURLWithPath: "build/preview.png"))
    print("✅ build/preview.png")
}

// MARK: - 메뉴바 라벨

struct MenuLabel: View {
    @EnvironmentObject var clock: Clock
    private var cfg = Config()

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle().stroke(.primary.opacity(0.25), lineWidth: 2)
                Circle().trim(from: 0, to: max(cfg.progress(clock.now), 0.001))
                    .stroke(.primary, style: .init(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 11, height: 11)
            Text(money(cfg.earned(clock.now)))
                .monospacedDigit()   // 없으면 숫자 바뀔 때마다 메뉴바가 출렁인다
        }
    }
}

// MARK: - 패널

/// 패널 로컬 상태. `@State`를 안 쓴다 — Command Line Tools에는 `SwiftUIMacros` 플러그인이
/// 없어서 Xcode 없이는 `@State` 확장이 실패한다. 이 앱은 CLT만으로 빌드하는 게 전제다.
final class PanelState: ObservableObject {
    @Published var showSettings = false
    @Published var glow = 0.0
}

struct PanelView: View {
    @EnvironmentObject var clock: Clock
    @AppStorage("annualSalary") private var annual = 50_000_000
    @AppStorage("startHour") private var start = 9.0
    @AppStorage("endHour") private var end = 18.0
    @AppStorage("workdaysPerYear") private var workdays = 250
    @AppStorage("scope") private var scope = Scope.day
    @StateObject private var ui = PanelState()

    private var cfg: Config { Config() }
    private var nowHour: Double { clock.now.hourOfDay }
    private var earned: Double { cfg.earned(clock.now) }
    private var progress: Double { cfg.progress(clock.now) }

    private var caption: String {
        let pct = "\(Int(progress * 100))%"
        if scope != .day {
            let w = Pay.workdays(scope: scope, now: clock.now)
            return "\(pct)  ·  근무일 \(Int(w.total - w.done))일 남음"
        }
        if nowHour < start { return "출근까지 \(hm(start - nowHour))" }
        if nowHour >= end { return "퇴근! 🎉" }
        return "\(pct)  ·  \(hm(end - nowHour)) 남음"
    }

    /// 게이지 양끝 라벨 — 기간의 시작과 끝
    private var bounds: (String, String) {
        switch scope {
        case .day:   return (clock24(start), clock24(end))
        case .month: let n = Calendar.current.range(of: .day, in: .month, for: clock.now)?.count ?? 30
                     return ("1일", "\(n)일")
        case .year:  return ("1월", "12월")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            scopePicker.padding(.top, 14)

            Gauge(title: "\(scope.rawValue) 번 돈", progress: progress, amount: earned,
                  caption: caption, from: bounds.0, to: bounds.1, glow: ui.glow)
                .frame(height: 200)
                .padding(.top, 8)
                .animation(.easeOut(duration: 0.5), value: earned)

            HStack(spacing: 8) {
                chip("초당", money(cfg.perSecond, 1))
                chip("\(scope.rawValue) 총액", money(cfg.total))
            }
            .padding(.top, 2)

            DisclosureGroup(isExpanded: $ui.showSettings) {
                VStack(alignment: .leading, spacing: 9) {
                    field("연봉 (세전)") {
                        TextField("", value: $annual, format: .number).frame(width: 108)
                    }
                    field("출근") {
                        DatePicker("", selection: hourBinding($start), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    field("퇴근") {
                        DatePicker("", selection: hourBinding($end), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    field("연간 근무일") {
                        TextField("", value: $workdays, format: .number).frame(width: 52)
                    }
                    Toggle("로그인 시 자동 실행", isOn: loginItem)
                        .toggleStyle(.switch).controlSize(.mini).tint(Ink.mint)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
                }
                .textFieldStyle(.roundedBorder)
                .padding(.top, 10)
            } label: {
                Text("설정").font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.dim)
            }
            .padding(.top, 16)

            Divider().overlay(.white.opacity(0.08)).padding(.top, 14)

            HStack {
                Text("SalaryTick").font(.system(size: 10)).foregroundStyle(.white.opacity(0.25))
                Spacer()
                Button("종료") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(Ink.dim)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(width: 320)
        .background(Ink.panel)
        .environment(\.colorScheme, .dark)
        // ₩10,000 넘길 때마다 한 번 번쩍
        .onChange(of: Int(earned / max(cfg.total / 50, 1))) { _, _ in
            withAnimation(.easeOut(duration: 0.18)) { ui.glow = 1 }
            withAnimation(.easeOut(duration: 0.9).delay(0.18)) { ui.glow = 0 }
        }
    }

    /// 기간 세그먼트. 시스템 Picker(.segmented)를 안 쓴다 — ImageRenderer가 못 그려서
    /// ./build.sh preview가 깨지고, 커스텀 다크 판에 시스템 컨트롤이 겉돈다.
    private var scopePicker: some View {
        HStack(spacing: 2) {
            ForEach(Scope.allCases) { s in
                Text(s.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(s == scope ? AnyShapeStyle(.black.opacity(0.82)) : AnyShapeStyle(Ink.dim))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(s == scope ? AnyShapeStyle(Ink.money) : AnyShapeStyle(Color.clear),
                                in: RoundedRectangle(cornerRadius: 7))
                    .contentShape(Rectangle())
                    .onTapGesture { scope = s }
            }
        }
        .padding(2)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.07)))
        .animation(.easeOut(duration: 0.15), value: scope)
    }

    private func chip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10)).foregroundStyle(Ink.dim)
            Text(value).font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit().foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.07)))
    }

    private func field<V: View>(_ label: String, @ViewBuilder _ control: () -> V) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
            Spacer()
            control()
        }
    }

    private func hm(_ hours: Double) -> String {
        let m = Int(hours * 60)
        return m >= 60 ? "\(m / 60)시간 \(m % 60)분" : "\(m)분"
    }

    private func clock24(_ h: Double) -> String {
        String(format: "%02d:%02d", Int(h), Int((h - Double(Int(h))) * 60 + 0.5))
    }

    /// Double(시) <-> DatePicker의 Date 사이 다리. 날짜는 오늘로 고정하고 시/분만 쓴다.
    private func hourBinding(_ value: Binding<Double>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.startOfDay(for: Date()).addingTimeInterval(value.wrappedValue * 3600) },
            set: { value.wrappedValue = $0.hourOfDay }
        )
    }

    private var loginItem: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { on in try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
        )
    }
}

// MARK: - 자체 검증

func selfTest() {
    let a = 50_000_000, wd = 250, s = 9.0, e = 18.0
    let perSec = Pay.perSecond(annual: a, start: s, end: e, workdays: wd)
    precondition(abs(perSec - Double(a) / (250 * 9 * 3600)) < 1e-9, "초당 수입")

    precondition(Pay.earned(annual: a, start: s, end: e, workdays: wd, nowHour: 8.0) == 0, "출근 전엔 0원")
    let full = Double(a) / Double(wd)
    precondition(abs(Pay.earned(annual: a, start: s, end: e, workdays: wd, nowHour: 18.0) - full) < 1e-6, "퇴근 시각 = 하루치")
    precondition(abs(Pay.earned(annual: a, start: s, end: e, workdays: wd, nowHour: 23.0) - full) < 1e-6, "퇴근 후 고정")
    precondition(abs(Pay.earned(annual: a, start: s, end: e, workdays: wd, nowHour: 13.5) - full / 2) < 1e-6, "절반")

    precondition(Pay.progress(start: s, end: e, nowHour: 8.0) == 0, "진행률 하한")
    precondition(Pay.progress(start: s, end: e, nowHour: 18.0) == 1, "진행률 상한")

    // ponytail: 야간 근무(퇴근<출근)는 0원 처리. 필요해지면 end에 +24 더하는 한 줄.
    precondition(Pay.perSecond(annual: a, start: 22, end: 6, workdays: wd) == 0, "역전 구간")
    precondition(Pay.perSecond(annual: 0, start: s, end: e, workdays: wd) == 0, "연봉 0")

    // 기간 집계 — 2026-09-14(월) 기준. 9월 평일 22일, 오늘 이전 평일 9일.
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
    let day = cal.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 13, minute: 30))!

    let m = Pay.workdays(scope: .month, now: day, cal: cal)
    precondition(m == (9, 22), "9월 근무일 \(m)")
    let y = Pay.workdays(scope: .year, now: day, cal: cal)
    precondition(y.total == 261, "2026년 평일 \(y.total)")

    // 하루 절반 지났으면 9.5/22
    let mp = Pay.periodProgress(scope: .month, now: day, dayProgress: 0.5, cal: cal)
    precondition(abs(mp - 9.5 / 22) < 1e-9, "월 진행률")

    // 주말엔 오늘 몫을 안 더한다
    let sat = cal.date(from: DateComponents(year: 2026, month: 9, day: 12, hour: 13))!
    precondition(Pay.periodProgress(scope: .month, now: sat, dayProgress: 0.5, cal: cal) == 9 / 22.0, "주말")

    print("✅ selftest 통과")
}
