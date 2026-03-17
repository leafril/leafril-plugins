# Study English 작성 규칙

## 목차
- 파일 구조 — 월별 디렉터리, 일별 파일
- 로그 파일 템플릿 — frontmatter, 형식
- 작성 원칙

---

## 파일 구조

### 경로
- 패턴: `english-study/{YYYY}/{MM}/{DD}.md`
- 예시: `english-study/2026/03/17.md`
- 하루에 하나의 파일. 같은 날 여러 세션이면 기존 파일에 추가한다.

## 로그 파일 템플릿

```markdown
---
created: YYYY-MM-DD
---

> [!error] ~~wrong expression~~ → **corrected expression**

> [!tip] "패턴 표현" — 어떤 상황에서 쓰는지
> - 변형 예문 1
> - 변형 예문 2
```

### frontmatter 필드

**필수:**
- `created`: 작성 날짜

### 형식 설명

**교정 callout (`[!error]`):**
- `~~취소선~~` — 틀린 표현 (원문 그대로)
- `**볼드**` — 교정된 표현
- 하나의 교정 = 하나의 `[!error]` callout

**패턴 callout (`[!tip]`):**
- `"패턴"` — 써먹을 수 있는 문장 틀. 빈칸은 `___`로 표시
- 변형 예문 — 같은 패턴의 실제 사용 예시 2~3개
- 더 자연스럽거나 간결한 대안 표현이 있으면 여기에 포함
- 문법 용어 대신 패턴과 예문으로 기억하게

**배치:**
- `[!error]`와 `[!tip]`는 항상 쌍으로 (교정 → 패턴 순서)
- 카테고리 제목(`### Category`) 없이 쌍만 나열

### 예시

파일: `english-study/2026/03/17.md`

```markdown
---
created: 2026-03-17
---

> [!error] ~~doesn't know how to transit between red and blue~~ → **doesn't know how to transition between red and blue**

> [!tip] "transition from A to B" — 상태 전환을 말할 때. transit = 교통/이동
> - transition from loading to loaded
> - transition smoothly between states

> [!error] ~~how rotating border light work~~ → **How does the rotating border light work?**

> [!tip] "How does ___ work?" — 작동 원리를 물을 때
> - How does this hook work?
> - How does React rendering work?
```

### 같은 날 추가 세션

같은 날 추가 교정이 발생하면 기존 파일 하단에 `[!error]` + `[!tip]` 쌍을 추가한다.

## 작성 원칙

1. **교정-패턴 분리**: `[!error]`로 틀린→교정을, `[!tip]`로 패턴+예문을 분리
2. **패턴 중심**: 문법 용어 대신 "패턴 + 상황 + 변형 예문"으로 기록
3. **원본 보존**: 사용자가 실제로 쓴 표현을 그대로 기록 (~~취소선~~)
4. **간결하게**: 설명은 1줄, 변형 예문은 2~3개로 제한
