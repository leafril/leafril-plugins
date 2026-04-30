# Output Template — `theme.css`

## 목차

1. [책임](#책임)
2. [파일 구조](#파일-구조)
3. [전체 템플릿](#전체-템플릿)
4. [Tailwind 4 utility 자동 생성](#tailwind-4-utility-자동-생성)
5. [theme.ts와 1:1 미러](#themets와-11-미러)
6. [Anti-patterns](#anti-patterns)

---

## 책임

**Tailwind 4 `@theme` 블록 + vanilla `:root` fallback**.

- DOM utility 자동 생성 — `bg-surface-cream`, `text-ink-primary`, `rounded-card` 등
- theme.ts의 *미러* — 같은 토큰을 CSS 변수 형태로
- Tailwind 4 사용자 → `@theme` 블록 활성화
- Tailwind 미사용 (vanilla CSS) 사용자 → `:root` fallback 주석 활성화

---

## 파일 구조

```css
/**
 * theme.css — <name> Tailwind 4 @theme + :root fallback.
 * theme.ts 의 미러. 토큰 값은 theme.ts 와 1:1 동일.
 */

@theme {
  /* color · radius · font · shadow · spacing · border-width */
}

/* :root fallback — Tailwind 미사용 시 주석 해제 */
/* :root { ... } */
```

---

## 전체 템플릿

```css
/**
 * theme.css — <name> Tailwind 4 @theme + :root fallback.
 *
 * theme.ts 의 미러. 토큰 변경 시 두 파일 함께 업데이트 (drift 방지).
 *
 * 사용:
 *   - Tailwind 4 → @theme 블록이 자동으로 utility 생성 (bg-* / text-* / rounded-* 등)
 *   - Tailwind 미사용 → 아래 :root 주석 해제 후 일반 CSS 변수로
 *
 * 합의 캔버스: tokens-preview.html
 */

@theme {
  /* ─── color ─── */
  --color-bg-overlay-dim: rgba(0, 0, 0, 0.5);                /* ★ 카운트다운 overlay */

  --color-surface-base: #FFFFFF;
  --color-surface-cream: #FFF8E1;
  --color-surface-panel-dark: #3E2723;
  --color-surface-border: #3E2723;                           /* ★ HUD 외곽선 */

  --color-ink-primary: #3E2723;
  --color-ink-secondary: #5D4037;
  --color-ink-muted: #795548;
  --color-ink-inverse: #FFFFFF;
  --color-ink-on-accent: #3E2723;
  --color-ink-stroke: #3E2723;

  --color-brand-primary: #FF4DA6;                            /* ★ 캐릭터·로고 */
  --color-brand-secondary: #E63988;

  --color-accent-yellow: #FFD54F;                            /* ★ 회전·GO */
  --color-accent-yellow-deep: #FFC107;
  --color-accent-sky: #81D4FA;                               /* ★ 스왑 */
  --color-accent-sky-deep: #29B6F6;

  --color-semantic-success: #8BC34A;
  --color-semantic-success-soft: #AED581;
  --color-semantic-danger: #F44336;
  --color-semantic-danger-deep: #D32F2F;
  --color-semantic-warning: #FFB74D;
  --color-semantic-info: #4FC3F7;

  /* tone (다양성 순환용) */
  --color-tone-yellow: #FFF176;
  --color-tone-orange: #FFB74D;
  --color-tone-pink: #F48FB1;
  --color-tone-sky: #81D4FA;
  --color-tone-green: #AED581;
  --color-tone-purple: #CE93D8;

  /* ─── radius ─── */
  --radius-xs: 4px;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 20px;
  --radius-2xl: 24px;
  --radius-pill: 9999px;
  /* role alias */
  --radius-card: 16px;     /* ★ 패널 */
  --radius-button: 20px;   /* ★ 액션 버튼 */

  /* ─── font ─── */
  --font-primary: "One Mobile Pop", "Pretendard", -apple-system, sans-serif;

  --font-size-sm: 0.875rem;
  --font-size-xl: 1.75rem;     /* ★ HUD */
  --font-size-2xl: 2rem;       /* ★ 액션 버튼 */
  --font-size-4xl: 3rem;       /* ★ 카운트다운 */

  /* ─── shadow ─── */
  --shadow-button: 0 4px 0 rgba(0, 0, 0, 0.25);              /* ★ 액션 버튼 */
  --shadow-card-soft: 0 4px 0 rgba(62, 39, 35, 0.08);        /* ★ HUD grounding */

  /* ─── spacing (4px base) ─── */
  --spacing-0: 0;
  --spacing-1: 0.125rem;   /*  2px */
  --spacing-2: 0.25rem;    /*  4px */
  --spacing-4: 0.5rem;     /*  8px */
  --spacing-6: 0.75rem;    /* 12px */
  --spacing-8: 1rem;       /* 16px */
  --spacing-12: 1.5rem;    /* 24px */
  --spacing-16: 2rem;      /* 32px */

  /* ─── border width ─── */
  --border-width-md: 3px;  /* ★ HUD 패널 */

  /* ─── mood (코드화 어려운 axis — 주석으로 보존) ─── */
  /* mood: vibrant, playful, plump, outline-less, round-eye, pinkfong */
}

/* ============================================================
   :root fallback — Tailwind 미사용 환경
   (Tailwind 4 의 @theme 은 자동으로 :root 에도 등록하므로
    Tailwind 사용 환경에선 아래 블록 *불필요*. Tailwind 안 쓸 때만 주석 해제.)
   ============================================================ */
/*
:root {
  --color-brand-primary: #FF4DA6;
  --color-accent-yellow: #FFD54F;
  --color-surface-cream: #FFF8E1;
  ...
}
*/
```

---

## Tailwind 4 utility 자동 생성

`@theme` 안 변수 접두사로 utility 자동 생성:

| 접두사 | 생성되는 utility | 예시 |
|---|---|---|
| `--color-*` | `bg-*` · `text-*` · `border-*` | `--color-brand-primary` → `bg-brand-primary` |
| `--radius-*` | `rounded-*` | `--radius-card` → `rounded-card` |
| `--font-size-*` | `text-*` | `--font-size-xl` → `text-xl` |
| `--font-*` | `font-*` | `--font-primary` → `font-primary` |
| `--shadow-*` | `shadow-*` | `--shadow-button` → `shadow-button` |
| `--spacing-*` | `p-*` · `m-*` · `gap-*` | `--spacing-4` → `p-4` |
| `--border-width-*` | `border-*` | `--border-width-md` → `border-md` |

DOM 컴포넌트:
```tsx
<div className="bg-surface-cream text-ink-primary rounded-card shadow-button p-4">
  ...
</div>
```

---

## theme.ts와 1:1 미러

토큰 값은 *항상 동일*. 형식만 다름:

```
theme.ts                            theme.css
──────────────────────────────────────────────────────────
palette.brand.primary       ↔↔↔   --color-brand-primary
palette.accent.yellow       ↔↔↔   --color-accent-yellow
palette.surface.cream       ↔↔↔   --color-surface-cream
palette.toneSet.pastel6[0]  ↔↔↔   --color-tone-yellow
radius.card                 ↔↔↔   --radius-card
fontFamily.primary          ↔↔↔   --font-primary
shadow.button               ↔↔↔   --shadow-button
```

토큰 변경 시 *두 파일 모두 함께 업데이트*. drift 발생 시 컴포넌트 일관성 깨짐.

미러 자동화: design-token-extractor가 *theme.ts를 source*로 두고 theme.css를 자동 생성. 사용자가 토큰 변경 시 design-token-extractor 재호출하면 두 파일 다시 sync.

---

## Anti-patterns

- **theme.ts 없이 theme.css만** — Phaser·canvas 사용처에서 토큰 import 불가
- **두 파일 drift** — 한쪽만 수정하면 컴포넌트가 다른 값 보게 됨
- **`:root`만 사용 (Tailwind 4 인데)** — `@theme` 블록 안 쓰면 utility 자동 생성 안 됨
- **변수명 색만** — `--blue-500` ❌. 역할 기반 (`--color-brand-primary`) ✅
- **★ 마커 누락** — 어느 변수가 코드에 사용 중인지 추적 불가
