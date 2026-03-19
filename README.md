# ScreenGuard

핸드폰 사용량 추적 + 앱 사용 제한 Flutter 앱 (Android 홈 화면 위젯 포함)

## 주요 기능

### 무료
- 오늘의 총 스크린 타임 실시간 확인
- 앱별 사용 시간 목록 조회 (많이 쓴 순 정렬)
- 앱별 하루 제한 시간 설정 (알림)
- 기본 사용량 통계 (오늘/주간 차트)

### 프리미엄
- 앱 강제 차단 기능
- 상세 통계 (월간, 카테고리별)
- 주간 리포트 이메일 발송
- 홈 화면 위젯 (사용 시간 실시간 표시)

## 스크린샷 미리보기

```
홈 화면: 원형 사용량 링 + 상위 3개 앱
앱 목록: 검색/정렬 가능한 전체 앱 사용 목록
제한 설정: 앱별 시간 제한 설정 (시간:분 피커)
통계: 도넛 차트 (오늘) + 바 차트 (주간)
```

## 플랫폼

**Android 전용** — iOS는 앱 사용량 API를 서드파티에 공개하지 않아 지원 불가

## 필요 권한

| 권한 | 용도 |
|------|------|
| `PACKAGE_USAGE_STATS` | 앱별 사용 시간 조회 (사용자가 직접 허용 필요) |
| `FOREGROUND_SERVICE` | 백그라운드 사용량 모니터링 |
| `RECEIVE_BOOT_COMPLETED` | 기기 재시작 후 자동 시작 |
| `POST_NOTIFICATIONS` | 제한 초과 알림 |

> **주의:** `PACKAGE_USAGE_STATS`는 일반 권한 요청으로 허용되지 않습니다.
> 설정 > 디지털 웰빙 및 자녀 보호 > 앱 타이머 권한 화면에서 직접 허용해야 합니다.
> 앱 첫 실행 시 자동으로 해당 설정 화면으로 이동합니다.

## 기술 스택

- **Flutter** 3.19+ / **Dart** 3.0+
- `usage_stats` — Android UsageStatsManager 네이티브 연동
- `fl_chart` — 도넛/바 차트
- `home_widget` — 홈 화면 위젯
- `provider` — 상태 관리
- `permission_handler` — 권한 처리

## 빌드 방법

```bash
# 의존성 설치
flutter pub get

# 디버그 빌드
flutter run

# 릴리즈 APK
flutter build apk --release

# 릴리즈 AAB (Play Store)
flutter build appbundle --release
```

## 최소 요구 사양

- Android 5.0 (API 21) 이상
- `UsageStatsManager`는 Android 5.0+에서 지원

## 수익 구조

```
무료 (기본 추적)
└── 오늘 사용량 확인
└── 앱별 사용 목록
└── 기본 제한 설정 (알림만)

프리미엄 (월 2,900원 / 연 19,900원)
└── 앱 강제 차단
└── 상세 통계 + 월간 리포트
└── 홈 화면 위젯
└── 여러 기기 동기화
```

## 프로젝트 구조

```
lib/
├── main.dart                      # 앱 진입점, 하단 네비게이션
├── core/
│   ├── theme/app_theme.dart       # 다크 테마 + 그린 액센트
│   └── services/usage_service.dart # 앱 사용량 조회 + 제한 관리
├── features/
│   ├── home/home_screen.dart      # 오늘 사용량 대시보드
│   ├── apps/app_list_screen.dart  # 앱별 사용량 목록
│   ├── limits/limit_screen.dart   # 앱별 제한 시간 설정
│   └── stats/stats_screen.dart    # 주간/월간 통계 그래프
└── widgets/
    ├── usage_ring.dart            # 원형 사용량 표시 위젯
    └── app_usage_tile.dart        # 앱별 사용량 타일

android/app/src/main/kotlin/com/screenguard/
├── MainActivity.kt                # Flutter MethodChannel 연결
└── UsageStatsPlugin.kt            # Android UsageStatsManager 래퍼
```
