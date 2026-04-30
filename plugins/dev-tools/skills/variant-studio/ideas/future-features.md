# Future Features — 박제

## 목차

1. [F1. 결과물에 추가 지시 (Plannotator-style annotation)](#f1-결과물에-추가-지시-plannotator-style-annotation)
2. [F2. variant 제거 (Quick remove)](#f2-variant-제거-quick-remove)
3. [F3. 갤러리 + 설치](#f3-갤러리--설치)
4. [F4. 디테일 variant 개발](#f4-디테일-variant-개발)
5. [구현 우선순위](#구현-우선순위-조건-충족-시)
6. [결정 기록](#결정-기록)

---

variant-studio MVP에는 포함되지 않았지만 *사용자가 명시적으로 원했던* 기능들. 진짜 필요해질 때까지 보류.

각 기능은 *조건이 충족될 때* 구현 검토. 조건 미충족 상태에서 미리 만들면 빈 갤러리 / 안 쓰이는 UI 같은 over-engineering 결과.

---

## F1. 결과물에 추가 지시 (Plannotator-style annotation)

### 사용자 발언

> "만들어진 결과물에서 추가적인 지시 가능 (Like Plannotator)"

### 무엇

생성된 시안 위에 직접 핀 주석을 떨어뜨리고 텍스트 instruction을 입력. 다음 라운드에서 LLM이 그 좌표·텍스트를 읽어 해당 시안만 수정.

### 구현 스케치

- 로컬 웹 서버 (Bun) + 시안 HTML iframe 로드
- 핀 모드 toggle → 클릭 위치에 marker + textarea
- 저장 시 `storage/sessions/<session-id>.json` 에 `[{variantId, x, y, text}]` 추가
- 다음 Claude turn에서 sessions JSON 읽어 prompt에 주입

### 구현 조건

- 채팅으로 텍스트 수정하는 빈도가 *너무 잦아질 때*
- 즉 "3번 카드의 상단 모서리 더 들리게" 같은 좌표·위치 지시가 반복될 때
- 그 전까진 채팅 텍스트로 충분

---

## F2. variant 제거 (Quick remove)

### 사용자 발언

> "결과물에서 마음에 안드는 variant 제거"

### 무엇

각 시안 우상단 🗑 버튼 1번 클릭으로 즉시 제거. 다음 양산 시 *해당 메타포 가족은 풀에서 제외* (반복 추천 회피).

### 구현 스케치

- 로컬 웹 UI에서 각 카드 위 controls overlay
- 🗑 클릭 → server에 POST → HTML 파일에서 해당 섹션 제거
- 메타포 ID를 sessions JSON에 `excluded` 리스트로 저장
- 다음 라운드에서 풀 추출 시 자동 제외

### 구현 조건

- 양산 후 제거가 *일상화*될 때
- 채팅으로 "3번 빼" 처리하는 게 자주 반복되어 마찰이 느껴질 때

---

## F3. 갤러리 + 설치

### 사용자 발언

> "마음에 드는 결과물 저장해서 갤러리 구경, 마음에 드는 컴포넌트 바로 설치해서 나중에 사용"

### 무엇

두 단계로 분리:

#### F3-a. 갤러리

- 마음에 든 시안에 ♥ 클릭 → 영구 저장
- `/gallery` 페이지에서 그리드뷰로 둘러보기
- 메타포 / 컴포넌트 종류 / 토큰 셋으로 필터

#### F3-b. 설치

- 갤러리에서 컴포넌트 선택 → "이 프로젝트에 설치"
- HTML/CSS → React (또는 Vue / Svelte) 컴포넌트로 변환
- 토큰 import 자동 연결
- 위치 제안 (`src/components/<Name>.tsx`)

### 구현 스케치

```
storage/
├── gallery.json              # index
└── components/
    └── 2026-04-29__sticker-card.html  # 원본 보관
```

저장 형식:
```json
{
  "id": "uuid",
  "name": "Sticker Peel — Pink Tape",
  "tags": ["card", "playful", "kids"],
  "tokens": "<token source>",
  "html": "...",
  "metaphor": "sticker",
  "component": "card",
  "createdAt": "2026-04-29"
}
```

### 구현 조건

#### F3-a 갤러리
- 동일 컴포넌트 디자인을 *여러 프로젝트에서* 쓰기 시작할 때
- 또는 갤러리 누적이 reference library 가치를 가질 때 (50개+)

#### F3-b 설치
- 갤러리에 충분히 컴포넌트가 쌓이고
- 동일 컴포넌트를 새 프로젝트에 *반복 사용*하는 패턴이 생길 때
- 그 전까진 채팅으로 "이걸 React 컴포넌트로 변환해줘" 한 번이면 충분

---

## F4. 디테일 variant 개발

### 사용자 발언

> "마음에 드는 테마에서 더 디테일한 variant 개발"

### 무엇

저장된 시안을 기반으로 *그 메타포 안에서* 세분화된 변형 N개 추가 생성. 변형 축은 사용자가 그때그때 텍스트로 명시.

예: "스티커 카드 골랐어. 색만 다른 5개 더" / "호버 인터랙션 다양화한 4개 더"

### 구현 스케치

- 갤러리 또는 시안 화면에서 🪄 버튼
- 다이얼로그로 변형 축 선택 (또는 자유 입력)
  - 색 (pastel6 → 다른 톤)
  - 크기 (S/M/L/XL)
  - 인터랙션 (호버 동작 다양화)
  - 상태 (lock/loading/disabled 등 추가)
- 다음 Claude turn 트리거 → *원본 시그니처 유지하고 지정 축만 변형*

### 구현 조건

- 한 시안 안에서 더 깊게 파는 작업이 *반복적*으로 발생할 때
- 채팅에서 "Sticker 카드 색만 바꿔서 5개 더" 같은 요청이 흔해질 때
- 그 전까진 채팅으로 우회 가능

---

## 구현 우선순위 (조건 충족 시)

```
F2 제거 > F3-a 갤러리 > F1 주석 > F3-b 설치 > F4 디테일
```

이유:
- **F2**: 가장 빈번한 액션. 가장 작은 UI 비용.
- **F3-a**: 저장은 클릭 1번. 누적되면 reference library 자산.
- **F1**: UI 복잡도 큼 (drag, 핀, popup, 좌표 저장). 채팅으로 우회 가능 기간 김.
- **F3-b**: 변환 로직이 컨텍스트 많이 필요. 갤러리 충분히 차야 가치 나옴.
- **F4**: 채팅 우회가 가장 쉬움. 마지막에.

## 결정 기록

신규 기능 검토 시 이 파일에 추가하고, 구현 시 아래에 결정 기록 남김:

```
## 결정 기록
- 2026-XX-XX: F2 구현 시작 — {조건 충족 트리거}
- 2026-XX-XX: F1 보류 — {이유}
```
