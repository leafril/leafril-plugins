# Output Template — `tokens.ts`

## 목차

1. [책임](#책임)
2. [파일 구조](#파일-구조)
3. [전체 템플릿](#전체-템플릿)
4. [작성 규칙](#작성-규칙)
5. [Anti-patterns](#anti-patterns)

---

## 책임

**raw 원자 값의 *카탈로그***. 어떤 색·간격·둥글기·폰트사이즈가 *존재*하는지만 정의. 어디 쓸지(역할)는 모름.

- 직접 import 비추천 (theme.ts 통해서 접근)
- 값의 풀(pool) — Material 50~900 톤 같은 *raw scale*
- theme.ts가 import해서 역할에 매핑

---

## 파일 구조

```ts
/**
 * tokens.ts — raw atomic value catalog.
 * 직접 import 비추천. theme.ts 의 역할 매핑을 통해 접근.
 */

// 1. Color scales (Material 50~900 또는 시그니처 톤)
const pink = { ... } as const;
const blue = { ... } as const;
// ...
export const colorScale = { pink, blue, ... } as const;

// 2. Radius scale
export const radiusScale = { ... } as const;

// 3. Spacing scale
export const spacingScale = { ... } as const;

// 4. Font size scale
export const fontSizeScale = { ... } as const;

// 5. Shadow scale (raw — 사용처별 alias는 theme.ts에)
export const shadowScale = { ... } as const;

// 6. Border width scale
export const borderWidthScale = { ... } as const;

// Types
export type ColorScale = typeof colorScale;
// ...
```

---

## 전체 템플릿

```ts
/**
 * tokens.ts — <name> raw atomic value catalog.
 *
 * 직접 import 비추천. theme.ts 의 역할 매핑을 통해 접근한다.
 *
 * 추출 출처: <입력 형태>
 * 추출 일시: <YYYY-MM-DD>
 *
 * 구조:
 *   1) colorScale       — 색 raw scale (Material 50~900 패턴)
 *   2) radiusScale      — radius raw scale (xs/sm/md/lg/xl/2xl/pill)
 *   3) spacingScale     — spacing raw scale (4px base)
 *   4) fontSizeScale    — font-size raw scale (rem)
 *   5) shadowScale      — shadow raw scale (CSS box-shadow string)
 *   6) borderWidthScale — border width raw scale
 *
 * 규칙:
 *   - 사용처 없는 raw 값 정의 X (선예약 금지)
 *   - ★ 마커로 *theme.ts 에서 역할로 채택된 값* 표시
 */

// ─────────────────────────────────────────────────────────────
// 1) Color Scale
// ─────────────────────────────────────────────────────────────

const pink = {
  100: "#FFE0F0",
  500: "#FF4DA6", // ★ brand.primary
  700: "#E63988", // ★ brand.secondary (pressed)
} as const;

const amber = {
  300: "#FFD54F", // ★ accent.yellow
  500: "#FFC107", // ★ accent.yellowDeep (pressed)
} as const;

const sky = {
  300: "#81D4FA", // ★ accent.sky
  500: "#29B6F6", // ★ accent.skyDeep (pressed)
} as const;

const brown = {
  500: "#795548",
  700: "#5D4037", // ★ ink.secondary
  900: "#3E2723", // ★ ink.primary / surface.border
} as const;

// 게임 공용 파스텔 (toneSet 후보)
const yellow = { 300: "#FFF176" } as const;  // ★ toneSet.pastel6[0]
const orange = { 300: "#FFB74D" } as const;  // ★ toneSet.pastel6[1]
// ...

const neutral = {
  white: "#FFFFFF",  // ★ surface.base
  cream: "#FFF8E1",  // ★ surface.cream
  black: "#000000",
} as const;

export const colorScale = {
  pink, amber, sky, brown, yellow, orange, neutral,
  // ...
} as const;

// ─────────────────────────────────────────────────────────────
// 2) Radius Scale
// ─────────────────────────────────────────────────────────────

export const radiusScale = {
  xs: "4px",
  sm: "8px",
  md: "12px",
  lg: "16px",   // ★ radius.card / panel
  xl: "20px",   // ★ radius.button
  "2xl": "24px",
  pill: "9999px",
} as const;

// ─────────────────────────────────────────────────────────────
// 3) Spacing Scale (4px base)
// ─────────────────────────────────────────────────────────────

export const spacingScale = {
  0: "0",
  1: "0.125rem",  //  2px
  2: "0.25rem",   //  4px
  4: "0.5rem",    //  8px
  6: "0.75rem",   // 12px
  8: "1rem",      // 16px
  12: "1.5rem",   // 24px
  16: "2rem",     // 32px
  24: "3rem",     // 48px
} as const;

// ─────────────────────────────────────────────────────────────
// 4) Font Size Scale
// ─────────────────────────────────────────────────────────────

export const fontSizeScale = {
  sm: "0.875rem",  // 14px — 본문·캡션
  xl: "1.75rem",   // 28px ★ HUD
  "2xl": "2rem",   // 32px ★ 액션 버튼
  "4xl": "3rem",   // 48px ★ 카운트다운
} as const;

// ─────────────────────────────────────────────────────────────
// 5) Shadow Scale
// ─────────────────────────────────────────────────────────────

export const shadowScale = {
  button: "0 4px 0 rgba(0, 0, 0, 0.25)",        // ★ 액션 버튼 chunky
  cardSoft: "0 4px 0 rgba(62, 39, 35, 0.08)",   // ★ HUD 패널 grounding
} as const;

// ─────────────────────────────────────────────────────────────
// 6) Border Width Scale
// ─────────────────────────────────────────────────────────────

export const borderWidthScale = {
  md: "3px",  // ★ HUD 패널 / 버튼
} as const;

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

export type ColorScale = typeof colorScale;
export type RadiusScale = typeof radiusScale;
export type SpacingScale = typeof spacingScale;
export type FontSizeScale = typeof fontSizeScale;
export type ShadowScale = typeof shadowScale;
export type BorderWidthScale = typeof borderWidthScale;
```

---

## 작성 규칙

- **`as const` 강제** — 리터럴 타입 보존, IDE 자동완성
- **★ 마커** — `theme.ts` 에서 *역할로 채택된* raw 값에 표시
- **사용처 짧게** — `// ★ accent.yellow` 처럼 *어느 역할로 쓰이는지*
- **단위 접미사** 권장 — `_MS`, `_PX` 같은 raw 숫자 토큰일 때
- **그룹별 별도 const** — `pink`, `amber` 등을 따로 선언하고 `colorScale`에서 모음

---

## Anti-patterns

- **역할 이름이 raw에 들어감** — `colorScale.brand` ❌. `brand`는 theme.ts에서 정의
- **사용처 없는 값** — Material 50~900 *전부* 정의 X. 시그니처로 채택된 톤만
- **alias 정의** — `radiusScale.card` ❌. card는 *역할*이라 theme.ts에 정의
- **JSDoc 누락** — 각 그룹 위에 한 줄 주석 (`/** Brand pink scale */`)
- **★ 마커 누락** — raw 값이 *어느 역할로 쓰이는지* 추적 어려움
