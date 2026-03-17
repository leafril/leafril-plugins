---
name: english-log
description: >
  Log English corrections and useful expressions from coding sessions.
  Trigger on "english-log", "english log", "영어 기록", or when 3+ corrections
  have been made in a session and the user is wrapping up.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# English Log

코딩 세션 중 발생한 영어 교정 내용과 유용한 표현을 기록하는 스킬.

핵심 가치: **반복되는 실수를 패턴으로 인식하고, 자연스러운 표현을 누적하는 것.**

## 설정

`~/.claude/note-plugins.json`에서 `noteRoot`를 읽는다. 파일이 없거나 `noteRoot`가 없으면 사용자에게 물어보고 저장한다.

## 작성 규칙

파일 구조, 템플릿은 [references/rules.md](references/rules.md)에 정의되어 있다.
실행 시 이 파일을 읽고 그에 맞춰 작성한다.

## 워크플로우

### Phase 1: 수집

현재 세션의 대화 히스토리에서 영어 교정 내용을 모두 수집한다.

### Phase 2: 확인

수집한 교정 내용을 표로 보여주고 확인을 받는다.
추가로 기록하고 싶은 표현이 있는지 물어본다.

### Phase 3: 파일 작성

1. references/rules.md를 읽는다
2. 오늘 날짜 파일(`{noteRoot}/english-study/{YYYY}/{MM}/{DD}.md`)이 있는지 확인한다
   - 있으면 → 기존 파일에 새 교정 내용 추가
   - 없으면 → 새 파일 생성
3. rules.md의 템플릿에 따라 작성한다

### Phase 4: 패턴 분석 (선택)

최근 로그 파일 3~5개를 확인하여, 같은 유형의 실수가 반복되면 리마인드 메시지를 출력한다.
반복 패턴을 인식하면 학습 효과가 높아지기 때문.

## 자동 감지 기준

세션 중 영어 교정이 쌓이면 마무리 시 기록을 제안한다.
단, 사용자가 영어로 작성하지 않은 세션에서는 제안하지 않는다.

## 호출 맥락별 동작

**수동 호출 (`/english-log`):**
- Phase 1 → 2 → 3 → 4 순서대로 실행
- Phase 2에서 확인을 받은 후 작성

**자동 호출 (세션 마무리 시 제안):**
- 교정 요약을 간단히 보여주며 기록 여부만 질문
- 사용자가 동의하면 Phase 3 → 4 실행 (확인 과정 생략)

## 판단 기준

### 교정 0개인데 수동 호출

교정 내용이 없으면 기록할 것이 없다고 알려주고, 대신 기록하고 싶은 표현이 있는지 물어본다.

## 대화 방식

- 메타데이터를 묻는 폼식 질문은 하지 않는다
- 디렉터리는 스스로 판단한다
