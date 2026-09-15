# SalaryTick

메뉴바에서 지금까지 번 돈이 1초마다 올라가는 걸 보여주는 macOS 앱.

```
┌ 메뉴바 ─────────────────┐
│  ⏱ ₩ 84,213             │
└─────────────────────────┘
```

## 설치

터미널(⌘ + 스페이스 → "터미널")에서 한 줄씩 실행합니다.

1. 개발자 도구 설치 — 처음 한 번만

```sh
xcode-select --install
```

2. 앱 설치

```sh
cd ~/personal/frontend/salary-tick
./build.sh install
```

`✅ /Applications/SalaryTick.app` 이 나오면 끝. 메뉴바 오른쪽에 금액이 뜹니다.
(Dock에는 뜨지 않습니다.)

## 사용

- 메뉴바 금액 클릭 → 패널. **설정**에서 연봉, 출퇴근 시각, 연간 근무일수 입력.
- **로그인 시 자동 실행** 켜두면 컴퓨터 켤 때마다 자동으로 뜹니다.
- 종료: 패널의 **종료** 버튼. 다시 켜기: 응용 프로그램 → SalaryTick.
- 업데이트: `./build.sh install` 다시 실행.

## 그 밖의 명령

```sh
./build.sh run   # 설치 없이 바로 실행
./build.sh test  # 계산 검증
./build.sh       # 빌드만
```
