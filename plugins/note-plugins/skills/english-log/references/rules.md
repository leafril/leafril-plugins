# Study English 작성 규칙

## 목차
- 파일 구조 — 날짜별 로그 파일
- 카테고리 — 교정 유형 분류
- 로그 파일 템플릿 — frontmatter, 형식
- 작성 원칙

---

## 파일 구조

### 일별 디렉터리
- 패턴: `english-study/{YYYY}/{MM}/{DD}/`
- 예시: `english-study/2026/03/17/`

### 로그 파일
- 패턴: `english-study/{YYYY}/{MM}/{DD}/{context}.md`
- 예시: `english-study/2026/03/17/SparkleButton 구현 분석.md`
- 역할: 세션의 작업 맥락별로 파일을 생성한다. 같은 날 같은 맥락이면 기존 파일에 추가한다.

## 카테고리

교정 내용을 아래 카테고리로 분류한다. 해당하는 카테고리만 사용한다.

| Category | Description | Example |
|---|---|---|
| Spelling | 철자 | studing → studying |
| Articles | 관사 (a/an/the) | new approach → a new approach |
| Word usage | 단어의 잘못된 사용 | memo (동사 ❌) → save a note |
| Prepositions | 전치사 | discuss about → discuss |
| Verb form | 동사 형태/시제 | needs → are needed |
| Natural phrasing | 더 자연스러운 표현 | I want to know how X is implemented → Can you walk me through how X works? |
| Sentence structure | 문장 구조 | Missing connectors, run-on sentences |

## 로그 파일 템플릿

```markdown
---
created: YYYY-MM-DD
corrections: N
categories: [category1, category2]
---

### {Category}
- ❌ `original expression`
- ✅ `corrected expression`
- 💡 explanation (왜 틀렸는지, 규칙이 뭔지)
```

### frontmatter 필드

**필수:**
- `created`: 작성 날짜
- `corrections`: 총 교정 수
- `categories`: 사용된 카테고리 목록

### 예시 1 — 기능 구현 세션

파일: `english-study/2026/03/17/SparkleButton 구현 분석.md`

```markdown
---
created: 2026-03-17
corrections: 2
categories: [word-usage, articles]
---

### Word Usage
- ❌ `I want to memo for later`
- ✅ `I want to save a note on this for later`
- 💡 "memo"는 명사. 동사로 쓰려면 "make a memo" 또는 "save a note"

### Articles
- ❌ `new approach and new skill needs for this case`
- ✅ `A new approach and a new skill are needed for this case`
- 💡 셀 수 있는 명사 단수형 앞에는 관사(a/an) 필요
```

### 예시 2 — API 설계 세션

파일: `english-study/2026/03/18/결제 API 엔드포인트 설계.md`

```markdown
---
created: 2026-03-18
corrections: 2
categories: [prepositions, natural-phrasing]
---

### Prepositions
- ❌ `I need to discuss about the endpoint naming`
- ✅ `I need to discuss the endpoint naming`
- 💡 discuss는 타동사. 전치사 about 불필요

### Natural Phrasing
- ❌ `How should I name this endpoint?`
- ✅ `What's a good naming convention for this endpoint?`
- 💡 단순 "어떻게 이름 짓지?"보다 convention을 묻는 게 더 구체적
```

### 같은 맥락 추가 세션

같은 날 같은 작업 맥락에서 추가 교정이 발생하면 기존 파일에 카테고리별로 항목을 추가하고, frontmatter의 `corrections` 수와 `categories`를 업데이트한다.

## 작성 원칙

1. **맥락 포함**: 어떤 상황에서 틀렸는지를 함께 기록해야 기억에 남음
2. **규칙 설명**: 왜 틀렸는지, 어떤 규칙인지를 💡로 기록
3. **원본 보존**: 사용자가 실제로 쓴 표현을 그대로 기록 (❌)
4. **교정 명확히**: 올바른 표현도 명확히 기록 (✅)
5. **간결하게**: 설명은 1~2줄로. 길어지면 핵심만
