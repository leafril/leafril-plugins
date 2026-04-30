# Quality Gates

## 목차

1. [Gate 1 — Commit (끝까지 밀어붙임)](#gate-1--commit-끝까지-밀어붙임)
2. [Gate 2 — AI slop 차단](#gate-2--ai-slop-차단)
3. [Gate 3 — 4축 디테일](#gate-3--4축-디테일)
4. [Gate 4 — Production-grade](#gate-4--production-grade)
5. [4 게이트 통과 체크리스트](#4-게이트-통과-체크리스트)

---

LLM이 무난한 default로 회귀하는 관성을 끊는 4개의 강제 체크포인트. 각 시안은 4개 모두 통과해야 한다.

frontend-design 스킬의 핵심 원칙을 흡수해 본 스킬 단독으로도 동등한 품질을 보장.

---

## Gate 1 — Commit (끝까지 밀어붙임)

### 룰

각 시안은 한 메타포·미감을 *극단까지* 밀어붙인다. **안전한 중간값은 시안의 가치를 죽인다.**

### 통과 vs 실패

| 컴포넌트 | 통과 | 실패 (회귀) |
|---|---|---|
| 카드 (스티커) | die-cut 외곽 + peel 모서리 + 워시 테이프 + 회전 | "스티커 느낌 카드" — 둥근 사각 + 라벨 |
| 카드 (레고) | stud + side seam + click snap + LEGO 양각 | "레고 같은 카드" — 컬러 블록에 동그라미 몇 개 |
| 카드 (마법진) | 회전 룬 ring + 별빛 ring + mystical pool + halo | "마법진 같은 원형 카드" — 원에 별 한두 개 |
| 모달 (셔터) | 셔터 흔들림 + 흑백→컬러 fade + 구멍 자국 + 셔터음 | "카메라 느낌 모달" — 둥근 사각에 카메라 아이콘 |
| 버튼 (엘리베이터) | 누름 LED + click sound + 깊은 inset + 빛나는 ring | "버튼" — 그냥 색 사각에 텍스트 |

### 메타포 다양성도 Commit의 일부

Commit은 *시그니처 디테일*만이 아니라 *메타포 선택 자체*에도 적용된다. 풀 안 메타포만 N개 고르면 *변형 시도가 commit 안 한 것* — LLM 클리셰 안에서만 변주.

| 통과 | 실패 (closed list bias) |
|---|---|
| 풀 밖에서 N의 50%+ 발굴 (도메인·문화·시대·자연 루트) | metaphor-pool.md 안에서만 N개 픽 |
| "오늘 사용자 어휘에 김밥·식판이 자주 나옴 → 식판 메타포 시도" | "풀에 트레이딩 카드 있으니 그거 쓰자" |

### 자가진단

> "이 카드를 *진짜 그 사물*이라고 1초 안에 인지할 수 있는가?"
>
> "이번 세션의 N개 메타포 중 *풀 밖*에서 발굴한 게 절반 이상인가?"

둘 중 하나라도 NO면 게이트 미통과.

---

## Gate 2 — AI slop 차단

### 룰

LLM 디폴트로 회귀하는 패턴을 명시적으로 차단.

### 차단 리스트

#### 글꼴
- ❌ Inter 단독 / Roboto / Arial / system-ui 단독
- ✅ 디스플레이 + 본문 페어링 (예: Bagel Fat One + Pretendard, Instrument Serif Italic + Geist)
- 변형마다 디스플레이 폰트를 다르게 가져 가면 톤 분기점이 자연 발생

#### 색
- ❌ 흰 배경 위 보라 그라디언트 (대표 cliché)
- ❌ 의미 없는 무지개 그라디언트
- ✅ 메타포에 맞는 톤 결정 (sticker = pastel, glass = saturated mesh, lego = primary)
- ✅ 토큰 시스템과 일관

#### 레이아웃
- ❌ 균등 그리드 + 직사각 카드만
- ❌ 모든 카드가 같은 비율·간격·정렬
- ✅ 메타포에 맞는 비율 (트레이딩 카드 = 세로, 표지판 = 가로, 마법진 = 원형)
- ✅ 회전·기울기·overlap 같은 grid breaking 적극 활용

#### 디테일 깊이
- ❌ 호버 transform 1개만 (translateY)
- ❌ 그림자 1단 (단순 box-shadow)
- ✅ 다중 inset shadow + outer shadow
- ✅ 호버에 motion + color + position 동시 변화

---

## Gate 3 — 4축 디테일

### 룰

모든 변형이 다음 4축 중 *최소 3축*에서 distinctive choice를 가져야 한다. 절반만 commit한 시안은 거른다.

### 4축

#### Typography
- 디스플레이 폰트와 본문 폰트 페어링 명시
- 메타포에 맞는 폰트 선택 (코믹 = Bangers, 레트로 = Press Start 2P, 손글씨 = Single Day)
- 사이즈·자간·줄간격 의도적 조절

#### Background
- 단색 ❌ (특별한 의도 없는 한)
- ✅ gradient mesh / 텍스처 / 패턴 / atmospheric effect / 별빛 / 도트
- 메타포의 *세계관*을 배경에 담음

#### Motion
- 페이지 진입 stagger animation
- 호버 마이크로 인터랙션 (단일이 아니라 *조합*)
- easing 곡선 의도 선택 (`cubic-bezier(0.22, 1, 0.36, 1)`처럼 물성 있는 곡선)

#### Layout
- asymmetry / overlap / 회전 / grid breaking
- 메타포에 맞는 비율
- 시각 위계의 의도 (어디에 시선이 먼저 가는지)

### 자가진단

각 시안마다 4축 중 *최소 3축*에 대해 **한 줄로 명시적 답변**을 작성한다 (속으로 "있는 것 같음"이 아니라 *기록*).

```
Variant N — {메타포}
  Typography: {예: Bagel Fat One + Pretendard, 카드 헤딩 32px tight}
  Background: {예: pastel mesh radial gradient + 도트 텍스처}
  Motion:     {예: stagger 0.1s + cubic-bezier(0.34, 1.56, 0.64, 1) bounce}
  Layout:     {예: -3deg 회전 + 마스코트가 카드 밖으로 튀어나옴}
```

3축 미만이면 게이트 미통과. 한 줄로 표현하기 어려운 축은 distinctive choice가 *없는 것*이다.

---

## Gate 4 — Production-grade

### 룰

시안용 fake markup 금지. **실제로 동작하고 보여줄 수 있는 코드**여야 한다.

### 필수

- ✅ working HTML/CSS — 브라우저 열면 바로 동작
- ✅ 모든 상태(default/completed/new 등)가 실제 시각화됨
- ✅ hover/active 인터랙션이 실제 작동
- ✅ 폰트 로드 (Google Fonts 등)
- ✅ 반응형은 *최소 데스크탑*에서 깨지지 않게

### 금지

- ❌ Lorem ipsum / placeholder 텍스트 (의미 있는 한국어/영어 라벨 사용)
- ❌ "추후 채움" / "TODO" 주석
- ❌ 보이지 않는 절반 (디자인은 했는데 코드는 빠진)
- ❌ inline 의도 메모 (`/* sticker effect here */` 같은 빈 주석)

### 자가진단

> "이 HTML 파일을 다른 사람에게 던졌을 때, 추가 설명 없이 바로 평가 가능한가?"

---

## 4 게이트 통과 체크리스트

각 시안 빌드 후:

- [ ] **Gate 1a**: 시그니처 3+개 모두 구현했는가? 1초 안에 메타포 인지 가능한가?
- [ ] **Gate 1b**: 이번 세션 N개 메타포 중 *풀 밖*에서 발굴한 게 50% 이상인가?
- [ ] **Gate 2**: AI slop 차단 리스트에 걸리는 것 없는가?
- [ ] **Gate 3**: typography / background / motion / layout 중 3축 이상에서 distinctive choice가 있는가?
- [ ] **Gate 4**: working code인가? 모든 상태와 인터랙션 구현됐는가?

하나라도 NO면 그 시안은 빌드 미완.
