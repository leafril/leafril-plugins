# Output Template — `tokens-preview.html`

## 목차

1. [책임](#책임)
2. [페이지 구조 (8 섹션)](#페이지-구조-8-섹션)
3. [section 1 — Mock UI](#section-1--mock-ui)
4. [section 2 — Role Tokens (swatch grid)](#section-2--role-tokens-swatch-grid)
5. [section 3~7 — ink / font / radius / shadow / spacing](#section-37--ink--font--radius--shadow--spacing)
6. [section 8 — Raw Scale](#section-8--raw-scale)
7. [Swatch 카드 패턴](#swatch-카드-패턴)
8. [도메인별 Mock UI 가이드](#도메인별-mock-ui-가이드)
9. [Anti-patterns](#anti-patterns)

---

## 책임

**시각 합의 캔버스** — 디자이너·기획자가 토큰을 *눈으로 검토*하는 정적 페이지.

- 8 섹션 구조로 모든 토큰 시각화
- 자체 `:root`에 토큰 등록 (외부 의존 0 — 단독 동작)
- Mock UI 섹션은 *실제 컴포넌트*에 토큰 적용한 모습
- 토큰 결정 기록·변경 사유 보존

레퍼런스: tower-battle 프로젝트의 `docs/palette-sample.html` (1228줄). 새 프로젝트는 그 구조를 *템플릿*으로.

---

## 페이지 구조 (8 섹션)

```
[Header — 제목 · 스코프 · 상태 범례]
1. Mock UI                ← 토큰 적용된 실제 컴포넌트 조합
2. Role Tokens            ← bg / surface / accent / semantic / brand / ink / toneSet 그룹별 swatch
3. ink                    ← 텍스트 토큰 + 실제 텍스트 sample
4. font                   ← fontFamily 페어링 + fontSize 단계별 시각화
5. radius                 ← 원자 스케일 7단계 + 실제 사용처
6. shadow                 ← mock 컴포넌트로 시각화
7. spacing                ← 4px base 스케일 시각화
8. Raw Scale              ← color scale (50~900) — "직접 사용 금지" 명시
[Footer — 합의 캔버스 · 토큰 정의 경로]
```

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <title><name> — Tokens Preview</title>
  <style>
    /* :root 에 모든 토큰을 CSS 변수로 (theme.ts·theme.css 와 1:1 매칭) */
    :root { ... }
    /* 페이지 chrome + Mock UI + swatch 스타일 */
  </style>
</head>
<body>
  <div class="page">
    <header>...</header>
    <section><h2>1. Mock UI</h2>...</section>
    <section><h2>2. 역할 토큰</h2>...</section>
    <section><h2>3. ink — 텍스트 토큰</h2>...</section>
    <section><h2>4. font — 폰트 토큰</h2>...</section>
    <section><h2>5. radius — 둥글기 토큰</h2>...</section>
    <section><h2>6. shadow — 그림자 토큰</h2>...</section>
    <section><h2>7. spacing — 간격 토큰</h2>...</section>
    <section><h2>8. 원자 스케일 (Raw)</h2>...</section>
    <footer>...</footer>
  </div>
</body>
</html>
```

---

## section 1 — Mock UI

*토큰 적용된 실제 컴포넌트 조합*. 흩어진 hex 가 아니라 *통합 시스템으로 살아있는 모습*. 한 화면에 보여야.

도메인에 맞춰 컴포넌트 결정 — [도메인별 Mock UI 가이드](#도메인별-mock-ui-가이드) 참조.

```html
<section>
  <h2>1. Mock UI (실제 사용 미리보기)</h2>
  <p class="desc">현재 코드에서 흩어진 색을 토큰으로 묶어 적용한 모습.</p>
  <div class="mock-stage">
    <!-- HUD / 카드 / 버튼 / 입력 등 도메인별 컴포넌트 -->
  </div>
</section>
```

`mock-stage`는 *작은 캔버스* — 배경부터 컨테이너 색까지 토큰 사용. 실제 화면 미니어처.

---

## section 2 — Role Tokens (swatch grid)

`bg / surface / accent / semantic / brand / ink / block / toneSet` 그룹별로 H3 + swatch grid.

```html
<section>
  <h2>2. 역할 토큰</h2>
  <p class="desc">컴포넌트는 이 그룹만 import. 직접 hex 사용 금지.</p>

  <h3>surface — 표면</h3>
  <div class="grid cols-4">
    <div class="swatch">
      <div class="chip light" style="background: var(--color-surface-cream)">cream</div>
      <div class="meta">
        <div class="name">surface.cream ✅</div>
        <code>#FFF8E1 ★ 따뜻한 배경</code>
      </div>
    </div>
    <!-- ... -->
  </div>

  <h3>accent — 강조</h3>
  <div class="grid cols-4"> ... </div>

  <h3>semantic — 상태</h3>
  <div class="grid cols-6">
    <!-- success / danger / warning / info / 등 -->
  </div>

  <h3>toneSet.pastel6 — 게임 공용 N톤</h3>
  <div class="grid cols-6">
    <!-- pastel 6 톤 인덱스 0~5 -->
  </div>
</section>
```

---

## section 3~7 — ink / font / radius / shadow / spacing

각 섹션은 *해당 토큰에 특화된 시각화*.

### 3. ink — 텍스트 토큰

각 ink role 별로 *실제 텍스트* 보여줌:

```html
<div class="row">
  <span class="label">ink.primary</span>
  <span class="h-1">타이틀 블록 쌓기</span>
</div>
<div class="row">
  <span class="label">ink.secondary</span>
  <span class="h-2">현재 라운드 정보</span>
</div>
<!-- ink.muted / inverse / stroke (text-stroke 강조) -->
```

### 4. font — 폰트 토큰

fontFamily 페어링 + fontSize 4단계 시각화:

```html
<div style="display: flex; gap: 16px; padding: 12px 16px;">
  <span style="width: 60px;">sm ✅</span>
  <span style="font-size: var(--font-size-sm);">본문 · 보조 UI · ABCDEF 12345</span>
  <span style="margin-left: auto;"><code>0.875rem · 14px</code></span>
</div>
<!-- xl / 2xl / 4xl 단계별 -->
```

### 5. radius — 둥글기 토큰

원자 스케일 7단계 swatch + *실제 사용처 mock* (버튼 + 패널 등):

```html
<div class="grid cols-4">
  <div class="swatch">
    <div class="chip light" style="background: var(--color-surface-cream); border-radius: var(--radius-xs);">xs · 4px</div>
    <div class="meta"><div class="name">--radius-xs</div><code>4px</code></div>
  </div>
  <!-- sm / md / lg / xl / 2xl / pill -->
</div>

<h3>실제 사용 위치</h3>
<div class="grid cols-3">
  <button style="border-radius: var(--radius-button);">게임 버튼 (20px)</button>
  <div style="border-radius: var(--radius-card);">HUD 패널 (16px)</div>
</div>
```

### 6. shadow — 그림자 토큰

각 shadow 토큰을 *mock 컴포넌트*로:

```html
<div class="grid cols-3">
  <div style="background: var(--color-accent-yellow); box-shadow: var(--shadow-button);">
    shadow-button ✅ ★
    <div>0 4px 0 black 25% — 액션 버튼</div>
  </div>
  <div style="background: var(--color-surface-base); box-shadow: var(--shadow-card-soft);">
    shadow-card-soft ✅ ★
    <div>0 4px 0 brown 8% — HUD 패널</div>
  </div>
</div>
```

### 7. spacing — 간격 토큰

수평 막대로 4px base scale 시각화:

```html
<div style="display: flex; align-items: center; gap: 12px;">
  <span style="width: 80px;">--spacing-4</span>
  <span style="height: 16px; width: var(--spacing-4); background: var(--color-accent-yellow);"></span>
  <code>0.5rem · 8px</code>
</div>
<!-- 1 / 2 / 4 / 6 / 8 / 12 / 16 / 24 단계별 -->
```

---

## section 8 — Raw Scale

*직접 사용 금지* 명시 후 color scale 가족별 (brown / amber / sky / yellow / orange / pink / green / purple / red):

```html
<section>
  <h2>8. 원자 스케일 (Raw — 직접 사용 금지)</h2>
  <p class="desc">참고용. 실제 코드는 위 역할 토큰을 통해서만 접근.</p>

  <h3>brown</h3>
  <div class="grid scale">
    <div class="swatch"><div class="chip light" style="background: var(--brown-50)">50</div></div>
    <div class="swatch"><div class="chip light" style="background: var(--brown-100)">100</div></div>
    <!-- 200 ~ 900 -->
  </div>

  <h3>amber / sky / ...</h3>
  <!-- 가족별 grid -->
</section>
```

가족당 한 줄 (10 컬럼 grid). ★ 표시로 *역할로 채택된 톤* 마킹.

---

## Swatch 카드 패턴

```html
<div class="swatch">
  <div class="chip light" style="background: var(--color-accent-yellow)">yellow</div>
  <div class="meta">
    <div class="name">accent.yellow ✅</div>
    <code>#FFD54F ★ 회전·GO</code>
  </div>
</div>
```

CSS:
```css
.swatch {
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(62, 39, 35, 0.08);
  background: var(--color-surface-base);
  display: flex;
  flex-direction: column;
}
.swatch .chip {
  height: 72px;
  display: flex;
  align-items: flex-end;
  padding: 8px 10px;
  font-size: 11px;
  font-weight: 700;
}
.swatch .chip.dark { color: var(--color-ink-inverse); }
.swatch .chip.light { color: var(--color-ink-primary); }
.swatch .meta { padding: 8px 10px 10px; font-size: 11px; color: var(--color-ink-secondary); }
.swatch .meta .name { font-weight: 700; color: var(--color-ink-primary); margin-bottom: 2px; }
.swatch .meta code { font-family: ui-monospace, monospace; font-size: 10.5px; color: var(--color-ink-muted); }
```

`.chip.dark/.light`는 *텍스트 가독성*용 (어두운 색에 흰 텍스트, 밝은 색에 검은 텍스트).

---

## 도메인별 Mock UI 가이드

section 1의 컴포넌트 조합. 도메인에 맞춰 결정.

| 도메인 | 권장 mock 컴포넌트 |
|---|---|
| **게임** | HUD 패널 · 액션 버튼 (회전·스왑·GO) · 블록 stack · 별 burst · 플랫폼 |
| **학습 앱** | 스테이지 카드 · 진행도 바 · 마스코트 캐릭터 · 진입 모달 |
| **일반 SaaS** | 상단 헤더 · 사이드바 · 카드 리스트 · primary CTA · 입력 필드 · 토스트 |
| **이커머스** | 상품 카드 · 가격 chip · 장바구니 버튼 · 카테고리 nav · 리뷰 별점 |
| **기타** | 사용자 명시 컨텍스트에서 추론 |

목적: *토큰이 살아있는 형태*로 보임. 흩어진 hex 가 아니라 *통합 시스템*.

### 게임 도메인 예시 (HUD)

```html
<div class="mock-stage">
  <div class="hud-panel">
    <span><span class="dot"></span>높이 12</span>
    <span>남은 블록 4</span>
  </div>
  <div class="stars">
    <div class="star" style="background: var(--color-tone-yellow)"></div>
    <!-- pastel6 6톤 -->
  </div>
  <div class="blocks">
    <div class="block">🐻</div>
    <div class="block">🐰</div>
    <!-- ... -->
  </div>
  <div class="platform"></div>
</div>
<div class="button-row">
  <button class="btn rotate">회전</button>
  <button class="btn swap">스왑</button>
  <button class="btn go">GO!</button>
</div>
```

각 컴포넌트가 토큰 사용 — `.hud-panel` 은 `var(--color-surface-base) + var(--color-surface-border) + var(--shadow-card-soft)`.

---

## Anti-patterns

- **Mock UI 섹션 누락** — *토큰만 보여주는 페이지*는 정보 가치 낮음. 토큰이 어떻게 사용되는지 한 화면에 보여야
- **`:root` 외부 의존** — preview HTML이 theme.css를 import하면 단독 동작 안 함. 자체 `:root`에 모든 토큰 등록
- **swatch에 hex만, ★ 마커 없음** — 어느 토큰이 *사용 중*인지 모름
- **Raw Scale을 위쪽에 배치** — section 8 (마지막)에 둬야 *역할 토큰 우선* 인지
- **role과 raw 섞임** — `bg-pink-500` 같은 raw + `bg-brand-primary` 같은 role 혼용 ❌. role만 사용 강제
