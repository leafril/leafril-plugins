---
name: daybook
description: >
  Write engineering daybook entries — decisions, problem-solving, TILs, and insights
  as structured daily markdown notes. Trigger on "daybook", "record this", "log this",
  "TIL", or intent to capture dev experiences for future reference.
---

# Daybook

Dave Thomas 스타일의 Engineering Daybook을 작성하는 스킬.
어떤 프로젝트에서든, 심지어 개발이 아닌 맥락에서든 사용할 수 있다.

핵심 가치: **"그때 어떻게 했지?"를 미래의 나에게 전달하는 것.**

## 설정

`~/.claude/note-plugins.json`에서 `noteRoot`를 읽는다. 파일이 없거나 `noteRoot`가 없으면 사용자에게 물어보고 저장한다.

## 작성 규칙

파일 구조, 템플릿, frontmatter, 태그, 작성 원칙은 모두 [references/rules.md](references/rules.md)에 정의되어 있다.
실행 시 이 파일을 읽고 그에 맞춰 작성한다.

## 워크플로우

### Phase 1: 파일 준비

1. references/rules.md를 읽는다
2. 디렉터리 생성: `{noteRoot}/engineering daybook/{YYYY}/{MM}/{DD}/`
   - 예: `engineering daybook/2026/03/01/`
   - 기존 디렉터리가 다른 형식(예: `03-March/01 Sun/`)이더라도 이 패턴을 따른다

### Phase 2: 섹션 파일 작성

사용자가 전달한 내용을 개별 섹션 파일로 작성한다.

1. **파일명 결정** — 핵심 주제를 파악하여 파일명을 정한다. 한눈에 무엇에 대한 기록인지 알 수 있어야 한다.
2. **frontmatter·본문 작성** — rules.md의 템플릿과 규칙에 따라 작성한다.

## 판단 기준

### 파일명

- 좋은 예: `API 네이밍 고민.md`, `S3 직접 업로드 시 Content-Type 설정 필수.md`
- 나쁜 예: `작업 기록.md`, `오늘 한 것.md`

### 새 파일 vs 기존 파일 덧붙이기

- 오늘 같은 주제의 파일이 이미 있다 → 덧붙인다
- 같은 기능인데 전혀 다른 문제다 → 새 파일
- 확신이 안 서면 사용자에게 물어본다

### Summary 콜아웃

모든 섹션 파일에 Summary 콜아웃을 작성한다. 레이블은 내용에 맞는 것만 골라 쓴다.

### TODO 콜아웃

후속 작업이 있을 때만 붙인다. 대화 중 사용자가 "이건 나중에 해야지" 같은 맥락을 언급하면 추가한다.

## 대화 방식

- 메타데이터를 묻는 폼식 질문은 하지 않는다. (조직명은? 프로젝트는? 태그는?)
- 기록의 맥락을 끌어내는 질문은 적극적으로 한다. (왜 그렇게 결정했나요? 다른 선택지는 없었나요? 어떤 문제가 있었나요?)
- 사용자가 충분한 내용을 이미 전달했으면 바로 작성한다. 부족할 때만 대화한다.
- 파일명, frontmatter, 레이블 선택은 스스로 판단하되, 애매하면 간결하게 물어본다.
