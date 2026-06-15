# MeetGrid

친구끼리 약속 시간을 정할 때 각자 가능한 시간을 입력하고, 가장 많이 겹치는 시간대를 추천해 주는 Flutter 앱입니다.

> 약속 그룹 생성, 초대코드 참여, 30일 시간표 선택, 추천 시간 확정까지 한 흐름으로 구현했습니다.

## 프로젝트 개요

친구들과 약속을 잡을 때 단체 채팅방에서 가능한 날짜와 시간을 계속 물어봐야 하는 불편함이 있습니다. MeetGrid는 이 과정을 앱 안의 그룹, 초대코드, 시간표, 추천 결과 흐름으로 단순화합니다.

사용자는 그룹을 만들고 초대코드를 공유합니다. 친구들은 같은 그룹에 들어와 가능한 시간을 체크하고, 앱은 시간대별 가능한 인원 수를 계산해 가장 적합한 약속 시간을 보여줍니다.

## 주요 기능

| 기능 | 설명 |
| --- | --- |
| Google 로그인 | Firebase Authentication 기반으로 사용자를 구분합니다. |
| 그룹 생성 | 약속 그룹을 만들고 초대코드를 발급합니다. |
| 초대코드 참여 | 친구가 공유한 코드로 같은 그룹에 들어갑니다. |
| 가능 시간 선택 | 오늘부터 30일 안에서 날짜와 시간대를 선택합니다. |
| 추천 결과 | 많이 겹치는 시간대를 인원 수와 진행 바로 보여줍니다. |
| 시간 확정 | 추천 시간 중 하나를 약속 시간으로 확정합니다. |
| 로컬 데모 | Firebase 설정이 없거나 Android 설정이 아직 없을 때 샘플 데이터로 실행됩니다. |

## 사용 흐름

1. 앱 실행 후 Google 계정으로 로그인합니다.
2. 그룹 탭에서 약속 그룹을 생성합니다.
3. 생성된 초대코드를 친구에게 공유합니다.
4. 친구는 초대코드로 같은 그룹에 참여합니다.
5. 시간표 탭에서 가능한 날짜와 시간을 선택합니다.
6. 결과 탭에서 겹치는 시간대를 확인합니다.
7. 가장 적합한 시간을 약속 시간으로 확정합니다.

## 기술 스택

| 구분 | 사용 기술 |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| State | Provider, ChangeNotifier |
| Backend | Firebase |
| Auth | Firebase Authentication, Google Sign-In |
| Database | Cloud Firestore |
| iOS Bundle ID | `jwlee.MeetGrid` |
| Android Package | `com.jwlee.meetgrid` |

## 프로젝트 구조

```text
lib/
├── main.dart
├── ui.dart
├── app_state.dart
├── models.dart
├── firebase_config.dart
└── firebase_group_repository.dart

android/
ios/
Firebase/
└── firestore.rules

docs/
├── screenshots/
└── video/
```

## 구현 포인트

### 1. 시간 슬롯 모델링

날짜 키와 시작 시간을 `TimeSlot`으로 표현합니다. 사용자별 선택 시간은 `Set<TimeSlot>`로 관리해 중복 선택을 막고 포함 여부를 빠르게 계산합니다.

### 2. 겹침 계산

그룹 멤버들이 선택한 모든 시간 슬롯을 모은 뒤, 각 슬롯마다 가능한 멤버 수를 계산합니다. 결과는 가능한 인원 수 기준으로 정렬해 추천 시간 목록에 보여줍니다.

### 3. Firebase 저장 구조

Firestore의 `groups` 컬렉션에 그룹 이름, 초대코드, 멤버 목록, 사용자별 가능 시간, 확정 시간을 저장합니다. 공개 저장소에는 민감한 로컬 Firebase 파일을 포함하지 않습니다.

### 4. UI 방향

전체 화면은 화이트톤을 기본으로 구성했고, 입력창, 카드, 버튼, 날짜 칩, 시간 슬롯은 둥근 모서리로 통일했습니다. 그룹, 시간표, 결과 탭을 나눠 시연 때 기능 흐름이 바로 보이도록 했습니다.

## Firebase 설정

### 공통

1. Firebase Console에서 프로젝트를 엽니다.
2. Authentication에서 Google 로그인을 활성화합니다.
3. Cloud Firestore를 생성합니다.
4. [Firebase/firestore.rules](Firebase/firestore.rules) 내용을 Firestore Rules에 반영합니다.

### iOS

iOS는 기존 Firebase 프로젝트의 설정값을 [lib/firebase_config.dart](lib/firebase_config.dart)에 반영했습니다.

확인할 값:

- Bundle ID: `jwlee.MeetGrid`
- URL Scheme: `com.googleusercontent.apps.411746177907-0tptp4s8jge60q6mgrj44h6ejlhsk5if`
- Google 로그인 URL Scheme은 [ios/Runner/Info.plist](ios/Runner/Info.plist)에 등록되어 있습니다.

### Android

Android에서 Firebase 원격 저장까지 사용하려면 Firebase Console에서 Android 앱을 추가해야 합니다.

1. Android package name을 `com.jwlee.meetgrid`로 등록합니다.
2. Google 로그인용 SHA 인증서를 Firebase Console에 추가합니다.
3. Firebase Android App ID를 확인합니다.
4. 실행할 때 아래처럼 App ID를 전달합니다.

```bash
flutter run --dart-define=FIREBASE_ANDROID_APP_ID=1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID
```

App ID를 전달하지 않으면 Android 앱은 로컬 데모 모드로 실행됩니다.

## 실행 방법

```bash
flutter pub get
flutter run
```

분석, 테스트, 빌드 확인:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

실제 iPhone 배포 빌드는 Xcode에서 `ios/Runner.xcworkspace`를 열고 Signing Team을 확인한 뒤 실행합니다.

## 발표 영상

YouTube 영상 링크: https://youtube.com/shorts/-5Kp7M3qCUU

영상은 앱의 목적과 핵심 사용 흐름을 소개합니다.

1. 앱을 만든 이유
2. 그룹 생성 및 초대코드
3. 가능한 시간 선택
4. 겹치는 시간 확인 및 확정
5. Firebase 저장 구조 설명

자세한 촬영 흐름은 [docs/video/demo-script.md](docs/video/demo-script.md)에 정리했습니다.

## 평가 기준 대응

| 평가 항목 | MeetGrid에서의 대응 |
| --- | --- |
| 효용성 | 친구 약속 시간 조율이라는 명확한 문제를 해결합니다. |
| 완결성 | 그룹 생성, 참여, 시간 입력, 추천, 확정 흐름을 구현했습니다. |
| 직관성 | 그룹, 시간표, 결과 탭으로 사용 흐름을 분리했습니다. |
| 라벨링 | 초대코드, 가능 시간, 추천 시간 등 이해하기 쉬운 용어를 사용했습니다. |
| 시각디자인 | 화이트톤 배경과 둥근 카드, 칩, 버튼으로 부드러운 화면을 구성했습니다. |
| 학습용이성 | 날짜와 시간 슬롯을 눌러 바로 선택할 수 있게 했습니다. |
| 피드백 | 로그인, 생성, 참여, 확정, 오류 상황을 메시지로 안내합니다. |
| 오류 정정 | 빈 입력, 없는 초대코드, Firebase 설정 실패 상황을 처리합니다. |
| 정보성 | README와 발표 영상 링크로 앱 목적과 사용법을 설명합니다. |

## 개발자

- jwlee1008
