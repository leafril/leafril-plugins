# Output Template — `theme.ts`

## 목차

1. [책임](#책임)
2. [파일 구조](#파일-구조)
3. [전체 템플릿](#전체-템플릿)
4. [paletteHex (Phaser 0xRRGGBB) 변환](#palettehex-phaser-0xrrggbb-변환)
5. [mood array](#mood-array)
6. [작성 규칙](#작성-규칙)
7. [Anti-patterns](#anti-patterns)

---

## 책임

**역할 매핑** — tokens.ts의 raw 값을 *시맨틱 이름*으로 묶음.

- 컴포넌트가 import하는 단위
- tokens.ts → 역할(palette/radius/...)로 변환
- Phaser·canvas용 0xRRGGBB 숫자 (`paletteHex`) 동시 출력
- mood array (코드화 어려운 시각 어휘)

다중 theme(다크/라이트) 추가 시 `theme.light.ts` / `theme.dark.ts` 분기. tokens.ts는 그대로.

---

## 파일 구조

```ts
import { colorScale, radiusScale, ... } from "./tokens";

// 1. palette — 색 역할 매핑
export const palette = { surface, ink, brand, accent, semantic, toneSet } as const;

// 2. paletteHex — Phaser 0xRRGGBB
export const paletteHex = { /* palette 와 동일 키 구조 */ } as const;

// 3. radius — 역할 alias (radius.card = radiusScale.lg)
export const radius = { ... } as const;

// 4. fontFamily / fontSize
export const fontFamily = { ... } as const;
export const fontSize = fontSizeScale;  // 그대로 사용 시

// 5. shadow / spacing / borderWidth
export const shadow = shadowScale;
export const spacing = spacingScale;
export const borderWidth = borderWidthScale;

// 6. mood — 시각 어휘 array
export const mood = [...] as const;

// Types
```

---

## 전체 템플릿

```ts
/**
 * theme.ts — <name> semantic role mapping.
 *
 * 컴포넌트가 import 하는 단위. tokens.ts 의 raw 값을 *역할*(surface/ink/brand/accent 등)
 * 로 묶어 의미를 부여한다.
 *
 * 합의 캔버스: tokens-preview.html (시각화·결정 기록)
 *
 * 다중 theme 지원 시:
 *   theme.light.ts / theme.dark.ts — tokens.ts 는 공유, 매핑만 다름.
 */

import {
  colorScale,
  radiusScale,
  spacingScale,
  fontSizeScale,
  shadowScale,
  borderWidthScale,
} from "./tokens";

// ─────────────────────────────────────────────────────────────
// 1) palette — 색 역할 매핑 (CSS hex)
// ─────────────────────────────────────────────────────────────

export const palette = {
  /** 화면·캔버스 배경 */
  bg: {
    overlayDim: "rgba(0, 0, 0, 0.5)", // ★ 카운트다운 overlay
  },

  /** 카드·패널·모달 표면 */
  surface: {
    base: colorScale.neutral.white,
    cream: colorScale.neutral.cream,
    panelDark: colorScale.brown[900],
    border: colorScale.brown[900], // ★ HUD 패널 외곽선
  },

  /** 텍스트·외곽선 */
  ink: {
    primary: colorScale.brown[900],
    secondary: colorScale.brown[700],
    muted: colorScale.brown[500],
    inverse: colorScale.neutral.white,
    onAccent: colorScale.brown[900], // 노랑·하늘 버튼 위 텍스트
    stroke: colorScale.brown[900],   // 텍스트 외곽선
  },

  /** 브랜드 — 정체성 */
  brand: {
    primary: colorScale.pink[500],
    secondary: colorScale.pink[700],
  },

  /** 강조 — 주요 액션 */
  accent: {
    yellow: colorScale.amber[300],     // ★ 회전 / GO / featured 패널 bg
    yellowDeep: colorScale.amber[500], // pressed
    sky: colorScale.sky[300],          // ★ 스왑
    skyDeep: colorScale.sky[500],      // pressed
  },

  /** 시맨틱 — 상태 전달 */
  semantic: {
    success: colorScale.green[500],
    successSoft: colorScale.green[300],
    danger: colorScale.red[500],
    dangerDeep: colorScale.red[700],
    warning: colorScale.orange[300],
    info: colorScale.sky[400],
  },

  /** 게임 공용 N톤 — 다양성용 순환 */
  toneSet: {
    pastel6: [
      colorScale.yellow[300],
      colorScale.orange[300],
      colorScale.pink[300],
      colorScale.sky[300],
      colorScale.green[300],
      colorScale.purple[300],
    ],
  },
} as const;

// ─────────────────────────────────────────────────────────────
// 2) paletteHex — Phaser 0xRRGGBB 숫자
//    palette 와 1:1 동일 키 구조. alpha 토큰은 사용처에서 분해.
// ─────────────────────────────────────────────────────────────

const toHex = (s: string): number => Number.parseInt(s.replace("#", ""), 16);

export const paletteHex = {
  surface: {
    base: toHex(colorScale.neutral.white),
    panelDark: toHex(colorScale.brown[900]),
    border: toHex(colorScale.brown[900]),
  },
  ink: {
    primary: toHex(colorScale.brown[900]),
    inverse: toHex(colorScale.neutral.white),
  },
  accent: {
    yellow: toHex(colorScale.amber[300]),
    sky: toHex(colorScale.sky[300]),
  },
  toneSet: {
    pastel6: [
      toHex(colorScale.yellow[300]),
      toHex(colorScale.orange[300]),
      // ...
    ],
  },
} as const;

// ─────────────────────────────────────────────────────────────
// 3) radius — 역할 alias
// ─────────────────────────────────────────────────────────────

export const radius = {
  card: radiusScale.lg,    // ★ 패널·카드
  button: radiusScale.xl,  // ★ 액션 버튼
  pill: radiusScale.pill,  // ★ 뱃지·칩
} as const;

// ─────────────────────────────────────────────────────────────
// 4) Typography
// ─────────────────────────────────────────────────────────────

export const fontFamily = {
  primary: '"One Mobile Pop", "Pretendard", sans-serif',
} as const;

export const fontSize = fontSizeScale; // raw scale 그대로 사용

// ─────────────────────────────────────────────────────────────
// 5) shadow / spacing / borderWidth
// ─────────────────────────────────────────────────────────────

export const shadow = shadowScale;
export const spacing = spacingScale;
export const borderWidth = borderWidthScale;

// ─────────────────────────────────────────────────────────────
// 6) mood — 시각 어휘 (코드화 어려운 axis)
// ─────────────────────────────────────────────────────────────

export const mood = [
  "vibrant",
  "playful",
  "plump",
  "outline-less",
  "round-eye",
  "pinkfong",
] as const;

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

export type Palette = typeof palette;
export type PaletteHex = typeof paletteHex;
export type Radius = typeof radius;
export type FontFamily = typeof fontFamily;
export type Mood = typeof mood;
```

---

## paletteHex (Phaser 0xRRGGBB) 변환

`#RRGGBB` 문자열을 `0xRRGGBB` 숫자로 변환하는 헬퍼:

```ts
const toHex = (s: string): number => Number.parseInt(s.replace("#", ""), 16);
```

palette 와 1:1 키 매칭으로 작성. **alpha 있는 토큰**(`bg.overlayDim` 같은 `rgba()`)은 paletteHex에서 *제외* — Phaser는 `(color, alpha)` 두 인자로 분해해서 받음. 사용처에서 인라인:
```ts
graphics.fillStyle(0x000000, 0.5); // bg.overlayDim 분해
```

---

## mood array

코드화 어려운 *시각 어휘*. variant-studio·frontend-design이 prose로 읽어 시그니처에 반영.

추출 시 다음 축에서 5~10개:

| 축 | 키워드 |
|---|---|
| 채도 | vibrant / saturated / muted / pastel |
| 톤 | playful / refined / serious / energetic / calm |
| 형태 | organic / geometric / round / sharp |
| 외곽선 | outline-less / thin-line / chunky-line |
| 캐릭터 | plump / lean / square / cute |
| 시대 | retro-90s / Y2K / vaporwave / modern |
| 도메인 | pinkfong / lego / ghibli / disney |

---

## 작성 규칙

- **tokens.ts import** — raw 값 *직접 정의 X*. `colorScale.pink[500]` 형태로 참조
- **JSDoc 그룹별** — `/** 강조 — 주요 액션 */` 처럼 역할 명시
- **★ 마커** — 사용처 짧게 (`★ 회전·GO`)
- **as const 강제** — IDE 자동완성·타입 안전
- **types export** — 다른 파일이 토큰 타입 참조 가능

---

## Anti-patterns

- **raw hex 직접 정의** — `brand: { primary: "#FF4DA6" }` ❌. `colorScale.pink[500]` 참조
- **paletteHex와 palette 키 불일치** — 한쪽에만 있는 키 ❌. 1:1 매칭 강제
- **mood 누락** — 시각 어휘 보존 안 하면 다른 스킬이 시그니처 못 잡음
- **사용처 없는 역할** — `palette.tertiary` 같이 사용처 0인 토큰 ❌
- **alpha 토큰을 paletteHex에 포함** — Phaser는 (color, alpha) 분해 받음. 인라인 처리
