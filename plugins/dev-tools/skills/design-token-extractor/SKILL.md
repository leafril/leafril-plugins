---
name: design-token-extractor
description: 시각 자료(이미지·Figma·기존 CSS·레퍼런스 사이트·톤 키워드)에서 디자인 토큰을 추출해 표준 형식(TS 객체 / CSS 변수 / JSON)으로 출력한다. color · typography · radius · shadow · spacing · motion · 시각 어휘(mood) 6+1 카테고리로 분리. variant-studio·frontend-design 등 다른 디자인 작업의 *입력*이 되도록 설계됨. "토큰 만들어줘", "디자인 시스템 추출", "이미지에서 색 뽑아줘", "톤 정리해줘", "theme.ts 만들어줘", "tokens.css 생성", "디자인 토큰 추출" 류 요청 시 트리거.
argument-hint: "[입력 형태] [출력 형식]"
allowed-tools: Read, Write, Bash, Glob, Grep, WebFetch
---

시각 자료를 받아 *재사용 가능한 디자인 토큰*으로 정리한다. 토큰은 다른 작업(컴포넌트 디자인·시스템 빌드·페이지 구현)의 *입력*으로 흐른다.

```
[시각 자료] → 카테고리화 → 표준 형식 출력 → (다른 스킬 입력)
```

## 인자 파싱

| 위치 | 의미 | 기본값 |
|---|---|---|
| `$ARGUMENTS[0]` | 입력 형태 (image · figma · css · url · keyword) | 없으면 Phase 1에서 질문 |
| `$ARGUMENTS[1]` | 출력 형식 (ts · css · json · all) | ts |

호출 예:
- `/design-token-extractor image ts` → 이미지 입력 + TS 객체 출력
- `/design-token-extractor keyword css` → 톤 키워드 입력 + CSS 변수 출력
- `/design-token-extractor` → 입력·출력 모두 Phase 1에서 질문
- 자연어 ("이 4장 이미지에서 토큰 뽑아줘") → 본문에서 자동 추출

## Phase 1 — 입력·도메인 confirm

`AskUserQuestion`으로 2개 질문 묶음:

1. **입력 형태** — image / figma / css / url / keyword
2. **도메인** — `tokens-preview.html`의 Mock UI 컴포넌트 결정:
   - 게임 / 학습 앱 / 일반 SaaS / 이커머스 / 기타

기본값 (질문 안 함):
- mood 분리: 항상 ON (시각 어휘 누락 방지)
- 저장 위치: `/tmp/...` (사용자 프로젝트 경로 명시 시 거기로)
- 출력 환경: **Tailwind 4 + Phaser/Canvas 표준** — 4 파일 고정 출력

### 출력 환경을 단일 표준(B)으로 고정한 이유

본 스킬은 *Tailwind 4 + 캔버스/게임 가능* 환경을 표준으로 가정. 이유:
- Tailwind 4가 현재 신규 프로젝트 표준
- 캔버스·동적 색 처리가 *언제든 추가될 가능성* 있음 (있어도 손해 없음, 없어도 단순)
- 환경별 분기는 *불필요한 결정 비용* — 사용자 환경에 안 맞는 파일은 무시하면 됨

다른 환경 사용자도 4 파일 중 *필요한 것만 채택*:
- Tailwind 4 only (캔버스 X) → `theme.css` + `tokens-preview.html`만 사용, TS 파일은 무시
- Tailwind 3 → `tokens.ts` + `theme.ts`를 자체 `tailwind.config`에 매핑
- CSS-in-JS → `tokens.ts` + `theme.ts`를 ThemeProvider 주입
- vanilla CSS → `theme.css`의 `:root` 부분만 사용

## Phase 2 — 입력 형태별 추출

[references/input-types.md](references/input-types.md)에 입력 형태별 절차 상세.

### image (이미지 N장)

1. `Read` 도구로 이미지 시각 분석 (Claude vision)
2. 다음 요소 추출:
   - **Color palette** — 주요 색 5~8개 (hex)
   - **Typography clue** — 글꼴 인상 (둥근/각진, 두꺼운/얇은, serif/sans)
   - **Shape language** — radius, 외곽선 두께, 형태 단순도
   - **Shadow style** — 있는지·강도·offset
   - **Mood keywords** — vibrant/muted, playful/refined, organic/geometric, plump/lean, 무선/유선
3. 색은 카테고리화 (primary brand / accent / semantic / surface / ink / tone)

### figma (Figma URL)

`figma-to-code` / `figma-implement-design` 스킬 + Figma MCP 도구로 토큰 추출.

### css (기존 CSS·TS 파일)

`Read` 후 `:root` 변수·`@theme` 블록·이미 있는 토큰 객체를 파싱. 누락된 카테고리만 추가 추출.

### url (레퍼런스 사이트)

`WebFetch`로 페이지 가져온 뒤 CSS 분석 + 시각 인상에서 토큰 추정.

### keyword (톤 키워드만)

사용자가 키워드만 줌 (예: "warm sticker kids" / "minimal premium" / "liquid glass")
→ 키워드 해석 후 토큰 자동 생성.

[references/input-types.md](references/input-types.md)에 키워드별 자동 생성 매핑.

## Phase 3 — 카테고리화 (6 + 1)

추출한 raw 데이터를 다음 카테고리로 정리. [references/token-categories.md](references/token-categories.md) 상세.

| 카테고리 | 항목 | 형식 |
|---|---|---|
| **1. color** | brand · accent · semantic · surface · ink · tone | hex |
| **2. typography** | family · size scale · weight · letter-spacing | string · rem |
| **3. radius** | xs/sm/md/lg/xl/2xl/pill | px |
| **4. shadow** | soft · chunky · glow · inset 등 사용처별 | CSS string |
| **5. spacing** | 4px / 8px base scale | rem |
| **6. motion** | easing 곡선 · duration scale | string · ms |
| **7. mood** | 시각 어휘 키워드 (별도 axis — 코드화 어려움) | string array |

mood는 토큰화 어려운 *시각 어휘*를 prose로 보존. 예:
```
mood: ["vibrant", "playful", "plump", "outline-less", "round-eye", "pinkfong"]
```

variant-studio·frontend-design이 mood를 prose로 활용해 *시그니처 디테일*에 반영.

## Phase 4 — 4 파일 표준 출력

**항상 4 파일을 생성**:

```
/tmp/<name>-tokens-<YYYY-MM-DD>/
├── tokens.ts            ← raw atomic scales (colorScale·radiusScale·...)
├── theme.ts             ← semantic role mapping (palette·radius·fontFamily·shadow + paletteHex Phaser)
├── theme.css            ← Tailwind 4 @theme + vanilla :root fallback
└── tokens-preview.html  ← 시각 합의 캔버스 (8 섹션, 도메인별 Mock UI)
```

### 4 파일 책임 분리

| 파일 | 책임 | 사용처 |
|---|---|---|
| **`tokens.ts`** | raw 원자 값 카탈로그 | 직접 import 비추천. theme.ts·preview HTML이 참조 |
| **`theme.ts`** | 역할 매핑 (palette/radius/...) + Phaser 0xRRGGBB | React/Vue 컴포넌트, Phaser·canvas·동적 색 |
| **`theme.css`** | Tailwind 4 `@theme` 블록 + vanilla `:root` | DOM utility (`bg-surface-cream`...), Tailwind 미사용 환경 호환 |
| **`tokens-preview.html`** | 시각 합의 캔버스 — 8 섹션 | 디자이너·기획자 검토, 토큰 결정 기록 |

### 4 파일 1:1 매칭 강제

```
tokens.ts.colorScale.pink[500]   ↔  theme.ts.palette.brand.primary
                                 ↔  theme.css.--color-brand-primary
                                 ↔  tokens-preview.html .swatch[brand.primary]
```

토큰 변경 시 4 파일 모두 함께 업데이트. 한쪽만 바뀌면 drift anti-pattern.

### `tokens.ts` vs `theme.ts` 분리 원칙

- **tokens.ts** — *값의 카탈로그*. 어떤 색·간격·둥글기가 *존재*하는지만 정의.
  - 직접 import 비추천 주석
  - colorScale / radiusScale / spacingScale / fontSizeScale / shadowScale
- **theme.ts** — *역할 매핑*. tokens 값을 *시맨틱 이름*으로 묶음.
  - 컴포넌트가 import하는 단위
  - palette / radius (역할 alias) / fontFamily / fontSize / shadow / paletteHex (Phaser용 0xRRGGBB)
  - mood array
- 다중 theme (다크/라이트) 추가 시 `theme.light.ts` + `theme.dark.ts`로 분기 자연스러움 — tokens.ts는 그대로

### `theme.css` 두 형식 동시 출력

```css
/* ============================================================
   Tailwind 4 @theme — utility 자동 생성 (Tailwind 4 사용자)
   ============================================================ */
@theme {
  --color-brand-primary: #FF4DA6;
  --radius-card: 16px;
  /* ... */
}

/* ============================================================
   :root fallback — Tailwind 미사용 환경
   (Tailwind 4 @theme이 자동으로 :root에도 등록하므로 위 블록만 있어도 됨.
    아래는 Tailwind 안 쓸 때만 활성화 — 주석으로 둠)
   ============================================================ */
/* :root {
     --color-brand-primary: #FF4DA6;
     --radius-card: 16px;
   } */
```

### 비-표준 환경 사용자

다른 환경에선 4 파일 중 *필요한 것만 사용*:
- **Tailwind 4 only (캔버스 X)** → `theme.css` + `tokens-preview.html`만, TS 파일 무시
- **Tailwind 3** → `tokens.ts` + `theme.ts`를 자체 `tailwind.config.ts`의 `theme.extend`에 매핑
- **CSS-in-JS** → `tokens.ts` + `theme.ts`를 ThemeProvider에 주입
- **vanilla CSS** → `theme.css`의 `:root` 주석 블록을 활성화

### ★ 마커·상태 범례

- **★** : 코드에 *이미 사용 중* (예: `★ 회전·GO`)
- **✅** : 합의 완료
- **❓** : 미정 — 검토 필요

### 선예약 금지

사용처 없는 토큰 정의 X. 첫 사용처 생기면 추가.

상세 템플릿:
- [references/output-overview.md](references/output-overview.md) — 4 파일 개요·매칭 매트릭스·명명·상태 범례
- [references/output-tokens-ts.md](references/output-tokens-ts.md) — `tokens.ts` 템플릿 (raw atomic scale)
- [references/output-theme-ts.md](references/output-theme-ts.md) — `theme.ts` 템플릿 (역할 매핑 + Phaser paletteHex)
- [references/output-theme-css.md](references/output-theme-css.md) — `theme.css` 템플릿 (Tailwind 4 @theme + :root fallback)
- [references/output-preview-html.md](references/output-preview-html.md) — `tokens-preview.html` 템플릿 (8 섹션 + 도메인별 Mock UI)

## Phase 5 — 다음 작업으로 흐름 안내

4 파일 출력 후 사용자에게:

```
✅ 토큰 추출 완료

📁 출력:
   /tmp/<name>-tokens-<date>/
   ├── tokens.ts            (raw scale 카탈로그)
   ├── theme.ts             (역할 매핑 + Phaser paletteHex)
   ├── theme.css            (Tailwind 4 @theme)
   └── tokens-preview.html  (시각 합의 캔버스)

🎨 mood: [vibrant, playful, plump, outline-less, round-eye, pinkfong]
🌈 시그니처: pink + cream + ink-brown + chunky shadow
✏️ 폰트 페어링: Bagel Fat One + Pretendard

📂 프로젝트 적용 권장 경로:
   - tokens.ts / theme.ts → src/<scope>/config/
   - theme.css            → src/app/globals.css 에 import (또는 내용 머지)
   - tokens-preview.html  → docs/

📂 다음 작업:
   - 카드 N개 변형  → /variant-studio card N (4 파일 자동 인식)
   - 페이지 디자인 → frontend-design
   - Figma push    → figma-generate-library

🔍 합의 캔버스 자동 open:
   open <tokens-preview.html경로>
```

`open <html>`을 자동 실행해 시각 미리보기 띄움.

## Anti-patterns

- **이미지 1장으로 전체 토큰 추정** — 1장은 부족, 최소 3~5장 권장 (다양한 컨텍스트 보여야 톤 정확)
- **mood 누락** — 시각 어휘는 토큰화 안 되니 *별도 axis로 보존* 필수. mood 누락하면 variant-studio가 시그니처 못 잡음
- **카테고리 섞임** — `accent`에 brand 색 넣거나 `surface`에 ink 색 넣으면 다른 스킬 사용 시 혼란
- **너무 많은 톤** — 색 50+개 추출하면 디자인 시스템 의미 X. *시그니처 5~10개*로 줄임
- **주석·★ 마커 누락** — 각 토큰의 *역할*과 사용처를 명시 안 하면 토큰 의미 흐려짐
- **HTML 미리보기 누락** — 시각 합의 캔버스 없이 코드 파일만 발행 시 디자이너·기획자 검토 불가, drift 발생
- **4 파일 1:1 매칭 깨짐** — 한쪽만 업데이트하면 drift. 토큰 변경 시 4 파일 모두 함께 변경
- **tokens.ts와 theme.ts 책임 섞임** — tokens.ts에 역할 이름(brand·surface) 넣거나 theme.ts에 raw hex 직접 정의 ❌. tokens는 *값 카탈로그*, theme은 *역할 매핑*
- **선예약** — "나중에 쓸 수도 있으니" 토큰 미리 만들기 X. 첫 사용처 생기면 추가

## Composition

- **variant-studio** — 본 스킬 출력을 직접 입력으로 받음
- **frontend-design** — 페이지·앱 디자인 시 토큰 입력
- **figma-implement-design / figma-to-code** — Figma 입력일 때 본 스킬과 협업
- **figma-generate-library** — 추출한 토큰을 Figma Variables로 push

## 호출 예

```
사용자: 이 이미지 4장에서 토큰 뽑아줘
       또는: /design-token-extractor image
       또는: "warm sticker kids 톤으로 토큰 만들어줘"
       또는: "기존 globals.css 정리해서 theme.ts로"

스킬 흐름:
  Phase 1: 입력·출력 형식 confirm        (1턴)
  Phase 2: 입력 형태별 추출              (1턴)
  Phase 3: 6+1 카테고리화                (Phase 2와 묶임)
  Phase 4: 표준 형식 출력 + 파일 저장    (1턴)
  Phase 5: 다음 작업 안내                (이후 채팅)
```

## 참조 파일

- [references/input-types.md](references/input-types.md) — 입력 형태별 추출 절차 (image · figma · css · url · keyword)
- [references/token-categories.md](references/token-categories.md) — 6+1 카테고리 상세 (역할·예시·anti-pattern)

### 출력 템플릿 (4 파일 표준)

- [references/output-overview.md](references/output-overview.md) — 4 파일 개요·매칭 매트릭스·명명·상태 범례
- [references/output-tokens-ts.md](references/output-tokens-ts.md) — `tokens.ts` 템플릿 (raw atomic scale)
- [references/output-theme-ts.md](references/output-theme-ts.md) — `theme.ts` 템플릿 (역할 매핑 + Phaser paletteHex)
- [references/output-theme-css.md](references/output-theme-css.md) — `theme.css` 템플릿 (Tailwind 4 @theme + :root fallback)
- [references/output-preview-html.md](references/output-preview-html.md) — `tokens-preview.html` 템플릿 (8 섹션 + Mock UI)
