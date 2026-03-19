# ScreenGuard - 프로젝트 설정 가이드

## 프로젝트 소개

ScreenGuard는 Android 기기의 앱 사용량을 추적하고 앱 사용을 제한하는 Flutter 앱입니다. 홈 화면 위젯(home_widget)을 통해 사용 통계를 빠르게 확인할 수 있으며, fl_chart로 시각화된 사용 현황을 제공합니다.

- **기술 스택**: Flutter (Dart), usage_stats, fl_chart, home_widget, permission_handler, provider
- **플랫폼**: Android
- **외부 API**: 없음 (로컬 기기 데이터 기반)

---

## 필요한 API 키 / 환경변수

ScreenGuard는 외부 API를 사용하지 않습니다. 별도의 API 키나 환경변수 설정이 필요하지 않습니다.

단, 앱 실행 시 아래 Android 권한을 사용자에게 요청합니다.

- **사용 정보 접근 권한** (`PACKAGE_USAGE_STATS`): 앱 사용량 통계 조회
- **앱 오버레이 권한** (`SYSTEM_ALERT_WINDOW`): 앱 사용 제한 오버레이 표시

---

## GitHub Secrets 설정 방법

Google Play 배포를 위한 서명 자동화가 필요한 경우, 저장소의 **Settings > Secrets and variables > Actions** 에서 아래 Secrets를 등록합니다.

```
KEYSTORE_BASE64          = <base64로 인코딩한 keystore 파일>
KEY_ALIAS                = <키 별칭>
KEY_PASSWORD             = <키 비밀번호>
STORE_PASSWORD           = <키스토어 비밀번호>
```

Keystore를 base64로 변환하는 방법:

```bash
base64 -w 0 your-keystore.jks
```

---

## 로컬 개발 환경 설정

### 사전 요구사항

- Flutter SDK 3.0.0 이상 ([https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
- Android Studio 또는 VS Code
- Android SDK (API 21 이상)

### 1. 저장소 클론

```bash
git clone https://github.com/sconoscituo/ScreenGuard.git
cd ScreenGuard
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. Android 권한 확인

`android/app/src/main/AndroidManifest.xml`에 아래 권한이 선언되어 있는지 확인합니다.

```xml
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

### 4. 애셋 확인

```
assets/
  images/   # 앱 내 이미지 파일
```

---

## 실행 방법

### 개발 빌드 실행

```bash
flutter run
```

> 실기기 또는 에뮬레이터가 연결되어 있어야 합니다. 앱 실행 후 사용 정보 접근 권한을 수동으로 허용해야 합니다.

### 릴리즈 APK 빌드

```bash
flutter build apk --release
```

빌드된 APK 위치: `build/app/outputs/flutter-apk/app-release.apk`

### 테스트 실행

```bash
flutter test
```
