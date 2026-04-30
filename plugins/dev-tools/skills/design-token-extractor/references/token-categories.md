# Token Categories — 6+1 분류 상세

## 목차

1. [Color (색)](#1-color-색)
2. [Typography (글꼴)](#2-typography-글꼴)
3. [Radius (둥글기)](#3-radius-둥글기)
4. [Shadow (그림자)](#4-shadow-그림자)
5. [Spacing (간격)](#5-spacing-간격)
6. [Motion (모션)](#6-motion-모션)
7. [Mood (시각 어휘 — +1 별도)](#7-mood-시각-어휘--1-별도)
8. [공통 원칙](#공통-원칙)

---

## 1. Color (색)

### 하위 카테고리

| 이름 | 역할 | 예시 |
|---|---|---|
| **brand** | 정체성 색. 캐릭터·로고·메인 액션. | primary / secondary |
| **accent** | 강조 보조색. CTA·하이라이트. | yellow / sky |
| **semantic** | 상태 전달. 미래 사용 대비. | success / danger / warning / info |
| **surface** | 표면·배경. | base(white) / cream / panel / overlay |
| **ink** | 텍스트·외곽선. | primary / secondary / muted / inverse / stroke |
| **tone** | 다양성용 파스텔/비비드 set. | pastel6 / vivid6 |

### 추출 휴리스틱

- 가장 빈번 + 시각적으로 강한 색 → brand
- 보조 강조 → accent (1~2개)
- 흰/크림/회색 → surface
- 검정/진한 갈색·보라 → ink
- 6+ 톤 다양성 있으면 → tone

### Anti-pattern

- 배경 색을 brand로 분류
- 일러스트 디테일 색을 시스템 색으로 분류 (눈동자 검정 등)
- 너무 많은 색 (50+) — 시스템 의미 X, 5~10개 시그니처로 좁힘

### 출력 구조

```ts
const colorScale = {
  // raw scale — 직접 import 비추천
  pink: { 100: ..., 500: ..., 700: ... },
} as const;

const palette = {
  brand: { primary: ..., secondary: ... },
  accent: { yellow: ..., sky: ... },
  semantic: { success: ..., danger: ... },
  surface: { base: ..., cream: ..., panel: ... },
  ink: { primary: ..., secondary: ..., muted: ..., stroke: ... },
  tone: { pastel6: [...] },
} as const;
```

---

## 2. Typography (글꼴)

### 하위 카테고리

| 이름 | 역할 | 예시 |
|---|---|---|
| **family** | 폰트 페어링 | display / body / mono |
| **size** | 사이즈 스케일 | sm / md / lg / xl / 2xl / 4xl |
| **weight** | 굵기 | (선택 — 단일 weight면 생략) |
| **letter-spacing** | 자간 | tight / normal / wide |

### 페어링 원칙

display + body 페어링 필수. 같은 family 단독 ❌.

좋은 페어링 예:
- "Bagel Fat One" (display chunky) + "Pretendard" (body sans)
- "Instrument Serif Italic" (display editorial) + "Geist" (body geometric)
- "Bangers" (display 만화) + "Black Han Sans" (body 한글 chunky)

피할 페어링:
- Inter 단독
- Roboto 단독
- system-ui 단독
- 같은 family display·body

### 출력 구조

```ts
const fontFamily = {
  display: '"Bagel Fat One", "Black Han Sans", sans-serif',
  body: '"Pretendard", system-ui, sans-serif',
  mono: '"JetBrains Mono", monospace',
} as const;

const fontSize = {
  sm: "0.875rem",
  md: "1rem",
  lg: "1.25rem",
  xl: "1.75rem",
  "2xl": "2rem",
  "4xl": "4rem",
} as const;
```

---

## 3. Radius (둥글기)

### 스케일

xs (4px) / sm (8px) / md (12px) / lg (16px) / xl (20px) / 2xl (24px) / pill (9999px)

### 추출

- 카드·버튼 등에 *반복적으로* 등장하는 radius 값
- 메타포가 *둥근*(스티커·캐릭터) → md~2xl 위주
- 메타포가 *각진*(brutalist·swiss) → 0~xs

### Anti-pattern

- arbitrary value (`rounded-[16px]`) 여러 곳 → 시맨틱 토큰으로
- 컴포넌트별 다 다른 radius — 시스템 일관성 손상

---

## 4. Shadow (그림자)

### 하위 토큰

사용처별로 단일 토큰 (사용처 늘어나면 추가):
- **soft** — 미묘한 grounding (`0 4px 0 rgba(0,0,0,0.08)`)
- **chunky** — 게임·키즈 톤 (`0 6px 0 rgba(0,0,0,0.25)`)
- **glow** — 강조 (`0 0 16px rgba(...)`)
- **inset** — 내부 음영
- **multi-layer** — Liquid Glass 류 (`inset + outer 조합`)

### 추출

이미지 분석 시:
- 평면적 → 약한 soft 또는 없음
- 게임·toy 톤 → chunky 0 6px 0 black
- glass·premium → multi-layer blur

### 출력

```ts
const shadow = {
  soft: "0 4px 0 rgba(42,26,26,0.08)",
  chunky: "0 8px 0 rgba(42,26,26,0.25), 0 14px 24px rgba(42,26,26,0.12)",
  glow: "0 0 16px rgba(255, 213, 79, 0.5)",
} as const;
```

---

## 5. Spacing (간격)

### 스케일

4px base — 0/1/2/3/4/6/8/10/12/16/20/24/32 (rem)

### 추출

이미지 분석으로는 *추정 어려움*. 시각 인상에서:
- 여백 넉넉 → 큰 spacing 단계 위주 (16/20/24/32)
- 빽빽 → 작은 단계 위주 (4/6/8)
- 토큰 시스템 정교화 시 추가

대부분의 경우 *기본 4px base scale*로 두고 시작 → 사용 중 보강.

---

## 6. Motion (모션)

### 하위 토큰

- **easing** — `cubic-bezier()` 곡선
- **duration** — short(150ms) / medium(300ms) / long(600ms)

### 추출

이미지 단독으로는 추정 불가. 다음 단서:
- 키즈·playful → spring/bounce easing (`cubic-bezier(0.34, 1.56, 0.64, 1)`)
- premium·minimal → smooth ease-out (`cubic-bezier(0.22, 1, 0.36, 1)`)
- 게임·action → snappy ease-in-out

mood 키워드에서 추론 가능.

### 출력

```ts
const motion = {
  easing: {
    bounce: "cubic-bezier(0.34, 1.56, 0.64, 1)",
    smooth: "cubic-bezier(0.22, 1, 0.36, 1)",
    snappy: "cubic-bezier(0.4, 0, 0.2, 1)",
  },
  duration: {
    short: "150ms",
    medium: "300ms",
    long: "600ms",
  },
} as const;
```

---

## 7. Mood (시각 어휘 — +1 별도)

### 왜 별도인가

색·radius·shadow는 *수치화* 가능 → 토큰으로 코드화.

하지만 다음은 코드화 어려움:
- "무선 vs 유선" (외곽선 유무)
- "plump vs lean" (캐릭터 비율)
- "vibrant vs muted" (채도)
- "playful vs refined" (전반 톤)
- "organic vs geometric" (형태 어휘)
- "round-eye" (눈 모양)
- "halftone" (텍스처)

이런 *시각 어휘*는 **prose 키워드 array**로 보존. variant-studio나 frontend-design 같은 다른 스킬이 이 prose를 읽어 시그니처에 반영.

### 추출

이미지 분석 시 다음 축에서 키워드 5~10개:

| 축 | 키워드 |
|---|---|
| 채도 | vibrant / saturated / muted / pastel |
| 톤 | playful / refined / serious / energetic / calm |
| 형태 | organic / geometric / round / sharp |
| 외곽선 | outline-less / thin-line / chunky-line |
| 캐릭터 | plump / lean / square / cute |
| 디테일 | minimal / detailed / cluttered |
| 시대 | retro-90s / retro-80s / modern / Y2K / vaporwave |
| 도메인 | pinkfong / lego / ghibli / disney / IKEA |

여러 축 조합한 *3~10개 키워드*가 mood가 됨.

### 출력

```ts
const mood = [
  "vibrant", "playful", "plump", "outline-less", "round-eye", "pinkfong"
] as const;
```

또는 prose 1줄:
```
mood: "vivid + 무선 + plump 캐릭터 + 큰 둥근 눈, pinkfong 톤"
```

### 어떻게 활용되나

variant-studio Phase 3에서:
> "mood가 'plump + outline-less'라 시그니처 디테일에 *외곽선 없는 둥근 형태* 강제"

frontend-design Phase 3에서:
> "mood가 'retro-90s + halftone'이라 배경에 halftone 도트 패턴 + scanline overlay"

mood 없으면 LLM이 *디폴트 톤*으로 회귀. 시각 정체성 흐려짐.

---

## 공통 원칙

### 시그니처 vs 시스템 분리

- **시그니처 디테일** (눈·표정·캐릭터 형태) → mood로 보존
- **시스템 토큰** (색·radius·shadow) → 코드 객체로 보존

### 사용처 표시

각 토큰의 *역할*을 주석으로 (tower-battle theme.ts 수준):

```ts
const palette = {
  accent: {
    yellow: "#FFD54F",     // ★ 회전 / GO / featured 패널 bg
    yellowDeep: "#FFC107", // pressed
  }
} as const;
```

### 선예약 금지

- 사용처 없는 토큰 정의 X
- "나중에 쓸 수도 있으니" 미리 만들지 X
- 사용처가 생기면 추가
- 즉 *first usage*에 토큰 추가

### Naming

- camelCase TS 또는 kebab-case CSS 변수
- 시맨틱 (`primary`, `secondary`) — 색 자체가 아닌 *역할*
- 예외: tone (다양성용)에서는 색 이름 OK (`pastel6.yellow`)

### 점진적 정교화

처음 추출 → 5~10개 시그니처 토큰만.
사용 중 발견되면 추가.
한 번에 50개 만들지 X.
