# SalaryTick (Windows)

Tauri + React + TypeScript. mac/App.swift 기능을 그대로 이식한 위젯 앱.

## 개발 환경

- Node.js
- Rust (`rustup` 설치 후 `cargo`/`rustc`가 PATH에 있어야 함)

```sh
npm install
npm run tauri dev
```

첫 실행은 Rust 의존성 컴파일 때문에 몇 분 걸립니다. 이후엔 incremental이라 빠릅니다.

## 스크립트

```sh
npm run tauri dev   # 개발 모드 실행
npm run test         # 계산 로직(pay.ts) 검증
npm run tauri build  # 설치파일 빌드
```

## 구조

- `src/lib/pay.ts` — 급여 계산 순수 함수 (mac Pay enum 대응, `pay.test.ts`로 검증)
- `src/components/Panel.tsx`, `Gauge.tsx` — 위젯 UI
- `src/hooks/` — 1초 tick, 설정 영속화(`tauri-plugin-store`), 자동실행(`tauri-plugin-autostart`)
- `src-tauri/src/lib.rs` — 트레이 아이콘, 창 숨김/종료 동작

## 릴리스

`v*` 태그를 push하면 GitHub Actions가 Windows 설치파일을 빌드해 Release 초안으로 올립니다 (`.github/workflows/release.yml`).

```sh
git tag v0.1.0
git push origin v0.1.0
```
