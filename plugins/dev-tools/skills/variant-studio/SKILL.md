---
name: variant-studio
description: 단일 atomic 컴포넌트(카드, 버튼, 뱃지, 모달, 헤더, 로딩 등)의 시각 변형 N개를 단일 HTML 파일로 양산해 비교·결정을 돕는다. 디자인 토큰 + 컴포넌트 명세 + 탐색 모드 3축으로 입력받아, 메타포 풀에서 서로 다른 가족을 추출하고 끝까지 commit한 시안을 비교 가능한 형태로 출력. "시안 N개 보여줘", "컨셉 비교", "N가지 변형", "디자인 시안 양산", "여러 디자인 안 만들어줘", "변형 만들어줘", "스타일 비교", "디자인 탐색", "다양한 시안" 류 요청 시 트리거.
argument-hint: "<컴포넌트 종류> [개수]"
allowed-tools: Read, Write, Bash, Glob, Grep
---

단일 atomic 컴포넌트의 디자인 시안을 *결정 가능한 형태*로 양산한다. 즉흥이 아니라 결정론적 흐름을 따른다:

```
3축 명세 → 메타포 풀에서 N개 추림 → 각 시안 끝까지 commit → 단일 HTML로 비교 출력
```

LLM의 무난한 default 회귀를 막기 위해 frontend-design 원칙을 흡수한 Quality Gates를 강제한다.

## 인자 파싱

`$ARGUMENTS`로 받는 토큰 규칙:

| 위치 | 의미 | 기본값 |
|---|---|---|
| `$ARGUMENTS[0]` | 컴포넌트 종류 (card · button · modal · badge · header · loading · chip · input 등) | 없으면 Phase 1에서 질문 |
| `$ARGUMENTS[1]` | 시안 개수 N (정수) | 5 |

호출 예:
- `/variant-studio card 5` → 컴포넌트=card, N=5
- `/variant-studio modal` → 컴포넌트=modal, N=5 (기본)
- `/variant-studio` → Phase 1에서 컴포넌트·개수 모두 질문
- 자연어 (예: "결제 카드 4개 컨셉 보여줘") → 본문에서 컴포넌트·N 추출

인자가 명시 안 됐거나 모호하면 Phase 1에서 채운다.

## Phase 1 — 3축 명세 confirm

### 분할 패턴 (AskUserQuestion 4개 한계 대응)

`AskUserQuestion`은 한 번에 max 4개 질문만 가능. 명세 항목은 5개 이상이라 다음 분할을 따른다:

**1차 — AskUserQuestion 4개 묶음 (선택지형 항목)**
- Component (카드 / 모달 / 버튼 / 뱃지 / 배너 / 페이지 헤더 등)
- 시안 개수 N
- Mode (max / min / theme / mixed / free)
- 비율 (가로형 / 세로형 / 정사각 / 자유)

**2차 — 추정값 + 자유 텍스트 confirm (Phase 2 진입 직전)**

자유 텍스트가 필요한 항목은 컨텍스트에서 *합리적 추정*하고 confirm 단계에서 한 번에 검증:
- 디자인 토큰 (입력 안 됐으면 design-token-extractor 호출 안내)
- 정보 슬롯 (라벨·아이콘·메타 등)
- 상태 목록 (default + completed/new/locked/loading 등)
- 인터랙션 (hover/active/focus/drag)

확정값을 사용자에게 보여주고 "이대로 진행 / 수정" 하나의 AskUserQuestion으로 묶음. 사용자가 "수정"을 고르면 자유 텍스트로 어떤 항목을 어떻게 바꿀지 받음.

이게 표준 패턴. 1차에 5+개 모두 욱여넣지 않는다.

### Axis 1 — Design tokens (시각 DNA, *입력 가정*)

본 스킬은 **토큰 입력을 가정**한다. 토큰 추출은 **`design-token-extractor` 스킬의 책임**.

받을 수 있는 형태:
- **추출된 토큰 파일** (`tokens.ts`, `tokens.css`, `tokens.json`) — design-token-extractor 출력 또는 기존 디자인 시스템
- **이미 있는 프로젝트 토큰** (`theme.ts`, `globals.css`, `tailwind.config.ts`)
- **추출된 토큰 객체 직접 명시** (인라인)

토큰이 *없을 때* 동작:

```
사용자 입력에 토큰·이미지·키워드가 있으면
   → "토큰 추출이 필요해. design-token-extractor 먼저 호출할게"
   → design-token-extractor 호출 (또는 사용자에게 호출 권유)
   → 추출 완료 후 본 스킬 재진입

사용자 입력이 컴포넌트 명세만 있으면
   → "톤은 뭘로 갈까?" Phase 1에서 질문
   → 톤 키워드만 받으면 → design-token-extractor 호출
   → 토큰 받은 뒤 본 스킬 진행
```

본 스킬은 토큰을 *변형의 필터*로만 사용 — color·radius·shadow·typography·motion·mood를 모든 시안에 적용. 토큰 자체를 만들거나 변경하지 않는다.

### mood 활용

토큰의 `mood` 키워드 array는 *시그니처 디테일에 직접 반영*:

```
mood: ["vibrant", "outline-less", "plump"]
  ↓
모든 시안에서:
  - 외곽선 0 또는 매우 얇게 (outline-less)
  - 캐릭터/형태가 둥글둥글 (plump)
  - 채도 높은 색만 사용 (vibrant)
```

mood 누락된 토큰은 *시각 정체성 약함* — design-token-extractor 재호출 또는 mood 보강 권유.

### Axis 2 — Component spec (기능 명세)

- **컴포넌트 종류**: 카드 / 버튼 / 뱃지 / 모달 / 헤더 / 로딩 / 칩 / 입력 등
- **정보 슬롯**: 라벨, 아이콘, 메타 정보, 상태 표시 등 표시할 데이터
- **상태**: default 외에 어떤 상태(completed / new / loading / disabled / locked / error / hover-only / selected)
- **인터랙션**: hover / active / focus / drag 등
- **비율 제약**: 가로형 / 세로형 / 정사각 / 자유

### Axis 3 — Mode (탐색 방향)

- **max** — 장식 강한 한쪽 끝 (시그니처 디테일 풍부)
- **min** — 덜어낸 다른 쪽 끝 (장식 제거, 본질만)
- **theme: <메타포>** — 특정 메타포 가족에서만 변주 (예: `theme: paper`, `theme: glass`)
- **mixed** — max·min·theme 자유 혼합 (기본값)
- **free** — 토큰 무시, 순수 craft 탐색 (별개 스튜디오 작업으로)

기본값: **mixed N=5**.

## Phase 2 — 메타포 발굴 (open prior, NOT closed list)

**중요한 인지 함정**: [references/metaphor-pool.md](references/metaphor-pool.md)는 *시드 카탈로그*이지 정답 후보 리스트가 아니다. 풀 안에서만 고르면 LLM 클리셰가 반복된다. **풀 밖에서 발굴한 메타포가 더 적합하면 그것을 우선한다.**

### 정량 룰

> **N개 시안 중 최소 50%는 풀 밖 메타포여야 한다** (N=4면 2개, N=6면 3개).
>
> 풀 안만 채우면 Quality Gate 1 (Commit) 위반으로 간주.

### 발굴 순서

**Phase 2-a: 자유 발굴 먼저** (풀 보지 말고)

다음 발굴 루트를 따라 메타포 후보 N+2개 brainstorm:

| 발굴 루트 | 질문 |
|---|---|
| **도메인 어휘** | 이 컴포넌트가 속한 서비스의 핵심 메타포는? (학습 앱→그림책·노트, 결제→영수증·지갑, 게임→트로피·인벤토리) |
| **사용자 문화권** | 사용자 문화의 친숙한 사물은? (한국→김밥·식판·놀이공원·간판) |
| **참조 콘텐츠** | 사용자가 언급한 게임·작품·앱의 시각 어휘는? (이전 대화 컨텍스트 활용) |
| **물리 사물 풀** | "이 컴포넌트가 만약 *물리 사물*이라면?" 자유 연상 |
| **시대·문화** | 1990s zine / 일본 80s / Swiss design / brutalist / Y2K / vaporwave 등 시대 미감 |
| **자연/생물** | 식물·곤충·결정·세포 등 비-인공 형태 |

**Phase 2-b: 풀 대조 (마지막 단계)**

자유 발굴 후 [references/metaphor-pool.md](references/metaphor-pool.md)와 대조:
- 풀에 있는 메타포 → 시그니처 빠르게 적용 가능 (시간 절약)
- 풀에 없는 메타포 → Quality Gates 적용해서 시그니처 직접 추출

**Phase 2-c: 가족 중복 체크 + 사용자 confirm**

같은 가족 두 개 제거 (스티커 + 폴라로이드는 둘 다 paper). 그 다음 사용자 confirm.

confirm은 단순 yes/no가 아니라 **메타포 N개 각각에 대해 keep / replace / remove 선택**. `AskUserQuestion` 사용:

```
question: "메타포 추림 결과 (풀 밖 X/N). 각 메타포 어떻게 할까?"
options (각 메타포마다):
  - keep — 진행
  - replace — 다른 가족에서 재발굴
  - remove — N에서 제외 (N-1로 진행)
```

각 메타포 별 한 줄 설명: `{풀 밖/풀 안} {메타포명} — {발굴 루트} — {시그니처 키워드 3개}`.

### 예외 — 사용자가 같은 가족 두 개를 명시 요청한 경우

사용자가 "스티커랑 폴라로이드 둘 다 보고 싶어"처럼 명시적으로 같은 가족 메타포를 둘 이상 요청하면, **사용자 의도가 가족 중복 룰보다 우선**. 가족 안에서 *시그니처 차이가 가장 큰 두 개*를 고르고 confirm 단계에서 사용자에게 차이점 명시:

> "스티커(die-cut peel · 회전) vs 폴라로이드(흰 프레임 · 손글씨) — 둘 다 paper지만 시그니처 분리 가능해. 진행?"

### 메타 룰 — 풀의 진화

> **풀 밖에서 발견한 좋은 메타포는 시안 빌드 후 `metaphor-pool.md`에 등록**한다.
>
> 풀은 닫힌 사전이 아니라 시간 따라 누적·진화하는 살아있는 자산. 등록 시 가족·시그니처 3개·발굴 출처 명시.

## Phase 3 — 각 시안 빌드

각 시안마다:

1. **메타포 시그니처 3+개 추출** — 그 사물이라면 *반드시* 있는 디테일
   - 예) 카드: 레고 = stud + side seam + click snap
   - 예) 카드: 스티커 = die-cut 외곽 + peel 모서리 + 워시 테이프
   - 예) 모달: 셔터 = 셔터 흔들림 + 흑백→컬러 + 구멍 자국
   - 예) 모달: 봉투 = flap 열림 + 우표 도장 + 종이 결
   - 예) 버튼: 엘리베이터 = 누름 LED + click sound + 깊은 inset
   - 예) 버튼: 발판 = 누르면 들어감 + 스프링 반동 + 그림자 압축
2. **토큰을 필터로 적용** — 색·radius·shadow·typography를 메타포에 입힘 (mode가 `free`가 아닌 한)
3. **시그니처 vs 토큰 충돌 시**: 메타포 시그니처 우선, 토큰 일부 양보 가능
4. **Quality Gates 4개 통과** ([references/quality-gates.md](references/quality-gates.md) 상시 적용)
5. **모든 상태 렌더** — Axis 2에서 명시한 상태 전부 시각화
6. **인터랙션 구현** — hover · active 최소

### 컴포넌트별 메타포 풀 적용 차이 (디폴트 권장 — 닫힌 매핑 ❌)

**중요**: 아래 표는 *사고가 막혔을 때 출발점*이지 닫힌 매핑이 아니다. **사용자 컨텍스트(이미지·문화·도메인 어휘·참조 콘텐츠)가 표보다 우선**한다.

같은 메타포 풀을 쓰지만 컴포넌트별로 *디폴트로 자연스러운 가족*이 다르다:

| 컴포넌트 | 디폴트 자연 | 어색한 편 |
|---|---|---|
| **카드** | Paper · Plastic · Game · Material | (대부분 OK) |
| **모달** | Spatial(문·창문) · Material(유리·셔터) · Paper(봉투) | UI Conventional |
| **버튼** | Plastic(누름) · Material(돌·금속) · 물리적 행동 어휘 | Paper · Spatial |
| **뱃지** | Cultural(스탬프·인장) · Game(트로피) · Material(보석) | Spatial |
| **헤더** | UI Conventional · Cultural(간판·표지판) | Paper |
| **로딩** | 자연/생물(세포·결정 분열) · 물리(파동) · Game(스피너) | Paper · Spatial |

### 표를 무시해야 하는 경우 (자주 일어남)

- **사용자가 이미지·레퍼런스 제공** → 그 시각 어휘에서 직접 메타포 발굴 (이번 dogfood test에서 *서커스 텐트 → 카드*가 표에 없는데 자연스러웠음)
- **사용자가 문화·도메인 어휘 명시** ("우리 앱은 도시락 컨셉") → 그 메타포가 어느 가족이든 우선
- **mode=free** → 표 무시 (제약 없음)
- **mode=theme** → 사용자가 지정한 메타포 가족 우선

표의 *목적*: 컨텍스트 0인 콜드 스타트일 때만 시드 제공. 그 외엔 사용자 컨텍스트 우선.

### Quality Gates 핵심 (frontend-design 흡수)

| Gate | 요지 |
|---|---|
| **1. Commit** | 안전한 중간값 금지. 한 메타포·미감을 극단까지 밀어붙임 |
| **2. AI slop 차단** | Inter·Roboto·Arial·system-ui 단독 ❌. 흰 배경 보라 그라디언트 ❌. 균등 그리드 + 직사각만 ❌ |
| **3. 4축 디테일** | typography / background / motion / layout 중 *최소 3축*에서 distinctive choice |
| **4. Production-grade** | placeholder · lorem · fake markup 금지. 실제 hover·상태 동작 |

상세는 [references/quality-gates.md](references/quality-gates.md).

## Phase 4 — 단일 HTML 출력

[references/output-template.md](references/output-template.md) 구조를 따른다.

파일 위치: `/tmp/variant-studio__<component>__<YYYY-MM-DD>.html`

페이지 구성:

1. **페이지 헤더** — 제목 · 의도 1줄 · 토큰·명세 요약
2. **각 컨셉 섹션** (반복):
   - 번호 + 제목 + tagline (예: `01 / 스티커 — STICKER · DIE-CUT · PEEL`)
   - 1단락 설명 (무엇 · 시그니처 · 장점 · 한계)
   - 모든 상태 카드를 row로 나열
3. **전체 비교 매트릭스** — pro / con / fit-context 각 1줄
4. **Decision guide** — 어떤 상황에 어떤 컨셉 적합한지

저장 후 `open <파일경로>`로 브라우저 자동 open.

## Phase 5 — 다음 라운드 신호

출력 후 사용자 액션을 채팅으로 안내:

- "X번 마음에 안 들어" → 해당 컨셉 제거 + 새 메타포로 1개 추가 양산
- "X번 좋아" → 그 컨셉을 더 깊게 (하위 변형 N개 — 색·크기·인터랙션 축으로)
- "토큰·명세 바꿀래" → Phase 1 재진입
- "다른 컴포넌트" → 새 세션

이 단계는 *수동 채팅*으로 처리. 자동화 UI(주석·갤러리·설치)는 [ideas/future-features.md](ideas/future-features.md)에 박제.

## Anti-patterns

- **풀 안에서만 메타포 픽** (50% 룰 위반 — LLM 클리셰 반복) ⚠️ 가장 흔한 함정
- **같은 가족 메타포 두 개** (스티커 + 폴라로이드 → 둘 다 paper, 차이 약함)
- **시그니처 절반만 commit** (스티커인데 die-cut 없음 → 그냥 둥근 사각이 됨)
- **토큰 무시** (이유 없이 색·radius 다름) — mode가 `free`가 아닌 한
- **상태 default만** (completed · new · loading 빠뜨림 → 비교 의미 약화)
- **hover 없는 정적 카드** (Production-grade 게이트 위반)
- **자유 발굴 단계 건너뜀** (풀부터 보면 발굴 사고가 닫힘 — Phase 2-a 필수)
- **비교 매트릭스 누락** (사용자 결정 도구 없음)
- **풀 밖 신규 메타포를 시안만 만들고 풀 등록 안 함** (메타 룰 위반 — 풀이 정체됨)

## Composition (다른 스킬과의 관계)

### 입력 사슬

```
[입력 자료] → design-token-extractor → tokens.ts/css/json
                                            ↓
                              variant-studio (본 스킬) → variants.html
```

- **design-token-extractor** — 토큰 추출 책임. 본 스킬 입력의 시작점. **토큰이 없을 때 반드시 먼저 호출**.

### 같이 쓰면 더 강한 스킬

- **frontend-design** — 본 스킬 Quality Gates가 그 핵심을 흡수했지만, 원본 스킬이 함께 활성화되면 더 강하게 push됨
- **figma-to-code** — Figma 입력일 때 design-token-extractor가 활용
- **프로젝트 디자인 가이드라인** (`.claude/rules/` 등) — 프로젝트 컨벤션이 있다면 토큰·명명 규칙 자동 흡수

## 호출 예

```
사용자: /variant-studio card 5
       또는: "결제 카드 컴포넌트 5개 컨셉 보여줘"
       또는: "사용자 뱃지 4가지 변형 만들어줘"
       또는: "헤더 디자인 시안 양산"

스킬 흐름:
  Phase 1: 3축 confirm Q&A          (1턴)
  Phase 2: 메타포 추림 + confirm    (1턴, 짧음)
  Phase 3-4: HTML 빌드 + 자동 open  (1턴, 가장 긴 작업)
  Phase 5: 다음 액션 안내           (이후 채팅)
```

## 참조 파일

- [references/metaphor-pool.md](references/metaphor-pool.md) — 메타포 카탈로그 (가족별 분류, 늘려가기 쉽게)
- [references/quality-gates.md](references/quality-gates.md) — 4 게이트 상세 (frontend-design 흡수)
- [references/output-template.md](references/output-template.md) — HTML 구조 템플릿
- [ideas/future-features.md](ideas/future-features.md) — 박제된 v2+ 기능 후보
