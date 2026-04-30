# Output Template

## 목차

1. [파일 위치](#파일-위치)
2. [페이지 구조](#페이지-구조)
3. [페이지 헤더](#1-페이지-헤더)
4. [컨셉 섹션 × N](#2-컨셉-섹션--n)
5. [비교 매트릭스](#3-비교-매트릭스)
6. [Decision guide](#4-decision-guide)
7. [시각 디테일 가이드](#시각-디테일-가이드) — 배경 · 타이포 · 진입 애니메이션 · 호버
8. [분할 출력 (Optional)](#분할-출력-optional)
9. [마지막 체크](#마지막-체크)

---

variant-studio가 출력하는 단일 HTML 파일의 구조 가이드. 사용자가 결정 가능한 형태로 시안을 비교하기 위한 표준화된 레이아웃.

## 파일 위치

```
/tmp/variant-studio__<component>__<YYYY-MM-DD>.html
```

예: `/tmp/variant-studio__card__2026-04-29.html`

## 페이지 구조

```
[1. 페이지 헤더]
[2. 컨셉 섹션 × N (반복)]
[3. 비교 매트릭스]
[4. Decision guide]
```

---

## 1. 페이지 헤더

```html
<header class="page-header">
  <h1>{컴포넌트 이름} — Variant Studio</h1>
  <p class="intent">{한 줄 의도. 무엇을 결정하기 위한 시안인가}</p>
  <div class="spec-summary">
    <span>Tokens: {토큰 출처}</span>
    <span>Component: {정보 슬롯 요약}</span>
    <span>States: {렌더된 상태 목록}</span>
    <span>Mode: {탐색 모드}</span>
  </div>
</header>
```

폰트는 디스플레이 + 본문 페어링. 디스플레이는 메타포 풀 톤에 맞춰 골라도 됨 (예: Bagel Fat One, Instrument Serif).

---

## 2. 컨셉 섹션 × N

```html
<section class="concept">
  <div class="concept-header">
    <div class="concept-num">01</div>
    <div>
      <div class="concept-title">{메타포 한국어 이름} ({Metaphor English})</div>
      <div class="concept-tagline">— TAG · KEYWORD · 3-WORD-DESC</div>
    </div>
  </div>
  <p class="concept-desc">
    {1단락 설명: 시그니처가 무엇 + 인터랙션 한 줄 + 장점 한 줄 + 한계 한 줄}
  </p>
  <div class="concept-row">
    <div class="card-wrap-with-state">
      [컴포넌트 시안 — Default 상태]
      <div class="card-state">Default</div>
    </div>
    <div class="card-wrap-with-state">
      [컴포넌트 시안 — Completed 상태]
      <div class="card-state">Completed</div>
    </div>
    <div class="card-wrap-with-state">
      [컴포넌트 시안 — New 상태]
      <div class="card-state">New</div>
    </div>
    [기타 상태...]
  </div>
</section>
```

### 작성 규칙

- **번호**: `01`, `02`... 두 자리 패딩
- **제목 한국어 + 영문 메타포 이름** 병기 (가독성 + 보편성)
- **tagline**: `— STICKER · DIE-CUT · PEEL` 처럼 3 키워드 dot-separated, 대문자
- **desc 1단락**: 무엇 / 시그니처 / 호버·인터랙션 / 장점 / 한계 (한 단락 4~5줄)
- **장점·한계 명시 필수** — 결정 도구가 됨

### concept-row 레이아웃

- 기본: `display: flex; gap: 32px; flex-wrap: wrap;`
- 상태 라벨은 카드 아래에 작게 (`bottom: -36px; font-size: 12px;`)
- 카드 진입 stagger animation (`@keyframes drop-in` + `animation-delay`)

---

## 3. 비교 매트릭스

페이지 끝에 모든 컨셉을 한눈에 비교.

```html
<section class="decision">
  <h2>한 줄 비교</h2>
  <div class="decision-grid">
    <div class="decision-cell">
      <h3>01 {메타포}</h3>
      <p>
        <span class="pro">↑</span> {장점 1줄}<br>
        <span class="con">↓</span> {한계 1줄}<br>
        <strong>fit</strong>: {적합 컨텍스트}
      </p>
    </div>
    [반복 N개]
  </div>
</section>
```

### 매트릭스 셀 규칙

- **pro / con / fit** 3줄로 통일 — 사용자가 N개 컨셉을 가로로 스캔 가능
- 한 줄당 7~12 단어 이내
- `pro` 색: green / `con` 색: red / `fit`: bold

---

## 4. Decision guide

상황별 추천 — "어떤 상황에 어떤 컨셉을 골라야 하는가".

```html
<section class="decision-guide">
  <h2>결정 가이드</h2>
  <div class="guide-grid">
    <div>
      <h3>시각 임팩트 우선</h3>
      <p>{컨셉 번호 + 이유}</p>
    </div>
    <div>
      <h3>확장성·정보 밀도 우선</h3>
      <p>{컨셉 번호 + 이유}</p>
    </div>
    <div>
      <h3>{도메인 정체성} 강조</h3>
      <p>{컨셉 번호 + 이유}</p>
    </div>
    <div>
      <h3>모드별 분리 전략</h3>
      <p>{역할별로 컨셉 분리하는 방안}</p>
    </div>
  </div>
</section>
```

상황 4개는 컴포넌트·도메인에 따라 조정 가능. 핵심은 *결정자가 선택할 frame을 제공*하는 것.

---

## 시각 디테일 가이드

### 배경
- 본문 배경은 cream / dark / mesh 중 토큰에 맞춰
- 페이지 가장자리 atmosphere (radial gradient soft tint)

### 타이포그래피
- 디스플레이 폰트는 페이지 헤더 + 컨셉 제목에서만
- 본문은 Pretendard / 시스템 폰트 (Inter 단독은 피함)
- 영문 헤더에는 italic serif (예: Instrument Serif Italic) 활용 가능

### 컨셉 구분 표시
- 가운데 점선 또는 dashed border로 컨셉 사이 분리
- 또는 컨셉 번호의 `--accent-yellow` 큰 폰트로 자체 분리

### 진입 애니메이션
- 모든 시안 카드에 `animation: drop-in 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) backwards;`
- `animation-delay`로 순차 등장 (0.1s, 0.2s, 0.3s...)

### 호버 인터랙션
- 카드마다 메타포에 맞는 호버 동작 (스티커 = 회전 풀리고 모서리 더 들림 / 마법진 = 룬 회전 가속 / 레고 = 5px 떠오름)

---

## 분할 출력 (Optional)

시안 수가 많을 때 (N ≥ 8):

- Part 1 (max 컨셉) / Part 2 (min 컨셉) 으로 시각 분할
- 가운데 `part-divider` 로 구분
- 비교 매트릭스도 part별로 나누어 표시

```html
<div class="part-divider">
  <span>PART 02 · SIMPLE</span>
</div>
```

---

## 마지막 체크

출력 전 자가검사:
- [ ] 모든 컨셉 섹션이 같은 구조 (번호 / 제목 / tagline / desc / row)
- [ ] 모든 시안에 hover 인터랙션 작동
- [ ] 모든 상태 (default + ...) 시각화됨
- [ ] 비교 매트릭스 모든 셀 채워짐 (pro · con · fit)
- [ ] Decision guide 4 frame 채워짐
- [ ] 폰트 Google Fonts 로드 확인
- [ ] 브라우저 자동 open 명령 실행 (`open <path>`)
