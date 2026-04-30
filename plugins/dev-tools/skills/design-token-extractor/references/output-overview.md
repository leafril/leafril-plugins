# Output Overview — 4 파일 표준

## 목차

1. [4 파일 개요](#4-파일-개요)
2. [출력 위치·네이밍](#출력-위치네이밍)
3. [4 파일 1:1 매칭 매트릭스](#4-파일-11-매칭-매트릭스)
4. [상태 범례·★ 마커](#상태-범례마커)
5. [공통 작성 규칙](#공통-작성-규칙)
6. [출력 후 안내 메시지](#출력-후-안내-메시지)

---

## 4 파일 개요

```
/tmp/<name>-tokens-<YYYY-MM-DD>/
├── tokens.ts            ← raw atomic scales (값 카탈로그)
├── theme.ts             ← semantic role mapping (역할 매핑 + Phaser paletteHex)
├── theme.css            ← Tailwind 4 @theme + :root fallback
└── tokens-preview.html  ← 시각 합의 캔버스 (8 섹션, 도메인별 Mock UI)
```

| 파일 | 책임 | 사용처 |
|---|---|---|
| **`tokens.ts`** | raw 원자 값 카탈로그 (colorScale·radiusScale 등) | 직접 import 비추천. theme.ts·preview HTML이 참조 |
| **`theme.ts`** | 역할 매핑 + Phaser paletteHex + mood | React/Vue 컴포넌트, Phaser·canvas, 동적 색 |
| **`theme.css`** | Tailwind 4 `@theme` + `:root` fallback | DOM utility 자동 생성, Tailwind 미사용 환경 호환 |
| **`tokens-preview.html`** | 시각 합의 캔버스 — 8 섹션 | 디자이너·기획자 검토, 토큰 결정 기록 |

**상세 템플릿**:
- [output-tokens-ts.md](output-tokens-ts.md)
- [output-theme-ts.md](output-theme-ts.md)
- [output-theme-css.md](output-theme-css.md)
- [output-preview-html.md](output-preview-html.md)

---

## 출력 위치·네이밍

### 임시 출력 (기본)

```
/tmp/<name>-tokens-<YYYY-MM-DD>/
```

`<name>`은 사용자 입력 또는 mood 첫 키워드 (예: `pinkfong`, `glass`, `sticker-warm`).

### 사용자 프로젝트 적용 권장 경로

```
<project>/
├── src/<scope>/config/
│   ├── tokens.ts
│   └── theme.ts
├── src/app/globals.css     ← @import "./theme.css" 또는 내용 머지
└── docs/
    └── tokens-preview.html
```

`<scope>`는 토큰의 적용 범위 (예: `features/game/<game>`, `marketing`, `core`).

---

## 4 파일 1:1 매칭 매트릭스

토큰 변경 시 **4 파일 모두 함께 업데이트**. 한쪽만 바뀌면 drift anti-pattern.

```
tokens.ts                       theme.ts                    theme.css                    tokens-preview.html
─────────────────────────────────────────────────────────────────────────────────────────────────────────────
colorScale.pink[500]    ──→    palette.brand.primary  ──→  --color-brand-primary  ──→   .swatch[brand.primary]
colorScale.amber[300]   ──→    palette.accent.yellow  ──→  --color-accent-yellow  ──→   .swatch[accent.yellow]
radiusScale.lg          ──→    radius.card            ──→  --radius-card          ──→   .swatch[radius.card]
shadowScale.button      ──→    shadow.button          ──→  --shadow-button        ──→   mock button shadow
fontSizeScale.xl        ──→    fontSize.xl            ──→  --font-size-xl         ──→   .h-1
```

### 흐름

```
사용자 입력 (이미지·키워드 등)
       ↓
   추출 + 카테고리화
       ↓
┌──────┴──────┐
│             │
tokens.ts    theme.ts (tokens import)
   │              │
   └──────┬───────┘
          ↓
     theme.css (theme.ts 미러)
          ↓
   tokens-preview.html (모든 토큰 :root에 등록)
```

theme.ts는 tokens.ts를 import. theme.css는 theme.ts의 *미러*. tokens-preview.html은 *독립적으로* 모든 토큰을 자체 `:root`에 등록 (시각 캔버스가 외부 의존 없이 동작).

---

## 상태 범례·★ 마커

토큰의 *라이프사이클*을 가시화.

| 마커 | 의미 | 전환 시점 |
|---|---|---|
| **❓** | 미정 — 검토 필요. 임시값일 수 있음 | 첫 등장 |
| **✅** | 합의 완료 — 디자이너·개발 합의 후 확정 | 합의 후 |
| **★** | 사용 중 — 코드에 *이미 사용*됨. 변경 시 영향도 큼 | 첫 사용처 등록 시 |

### 4 파일에 일관 적용

- **tokens.ts** 주석: `pink: { 500: "#FF4DA6" }, // ★ brand primary`
- **theme.ts** 주석: `accent: { yellow: amber[300] /* ★ 회전·GO */ }`
- **theme.css** 주석: `--color-accent-yellow: #FFD54F; /* ★ CTA */`
- **tokens-preview.html**: `<div class="name">accent.yellow ✅</div><code>#FFD54F ★ 회전·GO</code>`

새 토큰 추가 시:
1. 첫 등장 → ❓
2. 디자이너·개발 합의 → ✅로 승급
3. 코드에 첫 사용 → ★ 추가

이 시스템이 토큰을 *살아있는 자산*으로 만듦.

---

## 공통 작성 규칙

### JSDoc 주석 강제

각 토큰 그룹 위에 *역할·의도* 명시:

```ts
/** 강조 — 주요 액션 버튼·하이라이트 */
accent: {
  yellow: amber[300],     // ★ 회전 / GO / featured 패널 bg
  yellowDeep: amber[500], // pressed
}
```

### 사용처 짧게

★ 옆에 *어디서 쓰이는지* 한 단어 (`★ 회전·GO`, `★ HUD`, `★ 카운트다운`).

### 선예약 금지

- 사용처 없는 토큰 정의 X
- "나중에 쓸 수도 있으니" 미리 만들지 X
- 첫 사용처 생기면 추가 (first usage 원칙)

### Naming

- TS: camelCase (`palette.brand.primary`)
- CSS: kebab-case (`--color-brand-primary`)
- *역할* 기반 (`primary`, `secondary`) — 색 자체가 아닌 *역할*
- 예외: `tone` 그룹은 색 이름 OK (`pastel6.yellow`)

### 점진적 정교화

- 처음 추출 → *시그니처 5~10개* 토큰만
- 사용 중 발견되면 추가
- 한 번에 50개 만들지 X

---

## 출력 후 안내 메시지

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
