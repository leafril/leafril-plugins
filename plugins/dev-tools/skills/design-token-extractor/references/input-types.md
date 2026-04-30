# Input Types — 입력 형태별 추출 절차

## 목차

1. [image — 이미지 N장](#image--이미지-n장)
2. [figma — Figma URL](#figma--figma-url)
3. [css — 기존 CSS·TS 파일](#css--기존-csstS-파일)
4. [url — 레퍼런스 사이트](#url--레퍼런스-사이트)
5. [keyword — 톤 키워드만](#keyword--톤-키워드만)
6. [입력 혼합 (multi-source)](#입력-혼합-multi-source)

---

## image — 이미지 N장

### 권장 입력 수

- **최소 3장**, 권장 5~8장
- 1~2장은 부족: 한 장면만 보여서 *시그니처*를 *우연한 디테일*과 구분 어려움
- 8+장: 분석 시간 길어지고 다양성 과다 → 토큰 산만

### 추출 절차

1. **`Read` 도구로 이미지 시각 분석** — Claude의 vision 활용
2. 각 이미지에서 추출:
   - 주요 색 5~8개 (eyedrop 추정)
   - 외곽선 두께·유무
   - radius 인상 (둥근 정도)
   - shadow 인상 (있는지·강도·offset)
   - 캐릭터·일러스트 비율 (plump / lean)
   - 표정·세부 형태 어휘
3. **3장 이상 공통 패턴**만 시그니처로 채택. 1장 우연 디테일은 제외.
4. 색은 카테고리화 — primary·accent·semantic·surface·ink·tone
5. mood 키워드 추출 (시각 어휘 5~10개)

### 색 카테고리화 휴리스틱

- **brand primary**: 가장 빈번하게 등장하는 *눈에 띄는 색* (캐릭터·로고·액션 버튼)
- **accent**: 강조용 두 번째 색 (CTA 보조·하이라이트)
- **surface**: 배경·표면 (흰색·크림·sky 등)
- **ink**: 텍스트·외곽선 (검정·진한 갈색)
- **semantic**: success/danger/warning 추정 (없으면 비움)
- **tone (pastel set)**: 다양성용 6+ 톤 (있을 때만)

### Anti-pattern

- 이미지 *배경 톤*을 brand로 분류 (배경은 surface)
- 캐릭터 *눈동자 검정*을 ink로 분류 (눈동자는 일러스트 디테일이지 시스템 ink가 아님)
- 그림자 색을 별도 토큰으로 (shadow 안에 alpha로 흡수)

---

## figma — Figma URL

### 전제

Figma MCP 도구가 활성화되어 있어야 함 (`figma:figma-implement-design` 등).

### 추출 절차

1. **`figma-to-code` 스킬 활성화** — 토큰 매핑 가이드 적용
2. URL에서 fileKey + nodeId 파싱
3. `mcp__plugin_figma_figma__get_variable_defs` 호출 → Figma Variables 직접 추출
4. `get_design_context` 호출 → 컴포넌트 인스턴스에서 사용된 토큰 확인
5. Variables가 없으면 `get_metadata`로 노드 트리 분석 + `get_screenshot`으로 시각 인상 보강

### 출력

Figma Variables 구조 그대로 보존하되 본 스킬의 6+1 카테고리로 재정리.

---

## css — 기존 CSS·TS 파일

### 추출 절차

1. **`Read` 도구로 파일 읽기**
2. 다음 패턴 파싱:
   - `:root { --... }` CSS 변수
   - `@theme { --... }` Tailwind 4 블록
   - `export const palette = { ... }` TS 객체
   - `theme: { extend: { ... } }` Tailwind config
3. 누락된 카테고리 식별:
   - color 있는데 motion 없음? → 시스템 미완
   - radius 없음? → 자주 일어남 (별도 추가 필요)
4. 누락된 카테고리는 사용자에게 *추가할지 / 추출 생략*할지 물음

### 자주 발견되는 누락

- motion (easing 곡선·duration scale)
- mood (시각 어휘 — 보존된 적 거의 없음)
- shadow가 컴포넌트마다 인라인으로 흩어짐

---

## url — 레퍼런스 사이트

### 추출 절차

1. **`WebFetch` 도구로 페이지 가져오기**
2. CSS 분석:
   - inline `<style>` 블록
   - linked CSS 파일 (computed style 추정 어려우면 시각 인상으로)
3. **시각 인상 보강** — 페이지 스크린샷이 없으면 묘사 기반
4. 토큰 추출

### 한계

- CSS-in-JS·Tailwind 동적 생성·CSS Modules는 *raw 변수* 추출 어려움
- 시각 인상으로 추정해야 함 — 정확도 낮음
- 가능하면 "이 사이트 톤 같은 거" 정도의 *시드*로만 사용하고, 실제 토큰은 image 또는 keyword 입력으로

---

## keyword — 톤 키워드만

### 자동 생성 매핑

키워드 조합 → 토큰 자동 생성. 다음은 시드 매핑 (확장 가능):

| 키워드 | 색 톤 | radius | shadow | typography mood |
|---|---|---|---|---|
| `warm sticker kids` | cream + brown ink + pastel6 + amber accent | chunky (16~24px) | chunky (0 6px 0 black) | display: 둥글 chunky / body: 친근 sans |
| `minimal premium` | white + black + 1 accent | small (4~8px) | soft (0 1px 2px) | serif italic + clean sans |
| `liquid glass` | dark backdrop + translucent + iridescent | medium (16~24px) | multi-layer blur + inset glow | editorial italic + geometric sans |
| `retro arcade` | neon + black + scanline | sharp (0~4px) | hard offset (4px 4px 0) | pixel + mono |
| `pinkfong vivid` | pure pink/blue/yellow + cream + 무선 | round (12~32px) | soft chunky (0 4-8px 0) | round display + Pretendard |
| `editorial magazine` | off-white + black + accent | small | minimal | serif heavy + sans body |
| `swiss design` | white + black + red | 0 | none | Helvetica-class + grid |
| `1990s zine` | cyan + magenta + halftone | mixed | hard offset | hand-drawn + grunge |

### 키워드 조합 규칙

- 키워드 2~3개 조합 가능: `warm sticker kids` = warm + sticker + kids
- 조합 시 각 키워드의 시드를 가중평균
- 사용자가 *예외 명시* 가능 ("warm sticker kids인데 색은 푸른 톤")

### 한계

- 키워드 매핑은 *시드*. 실제 디자인은 사용자가 토큰 출력 후 fine-tune 필요
- 새 키워드(매핑에 없음)는 LLM 해석 → *상세도 낮음* — 가능하면 image 또는 css 입력 추가 권장

---

## 입력 혼합 (multi-source)

여러 형태 동시 입력 가능. 우선순위:

```
image > figma > css > url > keyword
```

이유: 직접 시각 자료 > 정형 토큰 > 추정.

예: 사용자가 "이 이미지 4장 + warm sticker kids 톤" → 이미지 우선 + keyword는 보강.

각 소스에서 추출한 토큰을 카테고리별 merge:
- 충돌 시 우선순위 높은 소스 채택
- 누락은 낮은 우선순위 소스로 채움

merge 규칙은 [token-categories.md](token-categories.md)에 카테고리별로 명시.
