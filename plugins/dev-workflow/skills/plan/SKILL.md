---
name: plan
description: 기능 설명을 받아 progress.json에 feature를 생성한다. Completion Criteria 포함. 구현 계획, 코드 레벨 설계, /plan, 새 기능 구현 전 계획 수립 시 사용.
argument-hint: <기능 설명>
allowed-tools:
  - AskUserQuestion
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
---

## Gotchas

- 이 skill은 **코드 레벨 구현 계획**을 세운다. 기획(what to build)은 별도 단계에서 다룬다
- Completion Criteria가 없으면 plan이 아니다. **Why**: 평가 단계가 이 기준으로만 채점한다 — 기준이 없으면 평가 자체가 불가능
- 코드를 작성하지 않는다 — 구조와 방향만 정한다. **Why**: plan과 implement를 분리해야 scope creep을 방지하고 사용자가 방향을 검토할 기회가 생긴다
- Plan이 확정되기 전에 구현을 시작하지 않는다. **Why**: Sprint Contract — 합의 없는 구현은 되돌리기 비용이 크다

# Plan — Implementation Plan Generator

기능 설명을 받아 `progress.json`에 feature 객체를 생성한다.
구현 단계에서 tasks가 수행되고, 평가 단계에서 completion_criteria가 채점된다.

## 입력 파싱

`$ARGUMENTS`를 기능 설명 텍스트로 처리한다. 인자가 없으면 AskUserQuestion으로 요청한다.

```
/plan 로그인 폼에 OAuth 구글 로그인 버튼 추가
/plan API 응답 캐싱 레이어 추가 — React Query 도입
```

### 요청 범위가 클 때

하나의 요청이 독립적으로 배포/테스트 가능한 여러 기능을 포함하면 feature를 분할한다. **Why**: feature가 크면 completion_criteria가 모호해지고 평가 채점이 부정확해진다.

- **분할 기준**: "이 부분만 머지해도 동작하는가?" — Yes면 별도 feature
- **분할 시**: AskUserQuestion으로 분할안을 제시하고 사용자 확인 후 각각 feature 생성
- **분할하지 않는 경우**: 기능이 크더라도 중간 단계가 단독으로 의미 없으면 하나의 feature로 유지 (tasks로 분할)

### 기존 feature와 기능적으로 겹칠 때

Step 1에서 progress.json을 읽었을 때 새 요청과 기능 범위가 겹치는 기존 feature가 있으면, AskUserQuestion으로 확인한다:
- "기존 feature `{id}`를 확장" — 기존 feature에 tasks/criteria 추가
- "별도 feature로 생성" — 독립적으로 추적
- "기존 feature 대체" — 기존 feature의 tasks가 모두 미완료일 때만 허용

## progress.json feature 스키마

이 skill이 생성하는 feature 객체의 스키마:

```json
{
  "id": "feature-id-kebab-case",
  "goal": "맥락 없이 읽어도 뭘 만드는지 알 수 있는 한 줄 요약",
  "decisions": [
    { "what": "최종 결정", "why": "이유" }
  ],
  "tasks": [
    { "task": "구체적 작업 단위", "done": false }
  ],
  "completion_criteria": [
    { "criterion": "검증 가능한 완료 기준", "verify": "bash:{cmd}|test|playwright:dom|playwright:visual", "met": false }
  ],
  "caveats": [
    "구현 시 주의할 함정이나 제약"
  ]
}
```

### completion_criteria 작성 규칙

각 기준은 `verify` 필드로 검증 방법을 명시한다. 평가 단계에서 이 필드를 보고 기계적으로 실행한다.

| verify 값 | 검증 방법 | 사용 시점 |
|-----------|-----------|-----------|
| `bash:{command}` | 명령어 실행, exit code 0이면 PASS | 빌드, 타입 체크, lint 등 CLI 한 줄로 확인 가능한 것 |
| `test` | criterion 기반 테스트 파일 탐색 → 실행 | 로직, 구조, 데이터 흐름 등 코드로 검증 가능한 것 |
| `playwright:dom` | snapshot + evaluate로 DOM 요소/텍스트/속성 확인 | 요소 존재, 텍스트 내용, 개수 등 구조적 확인 |
| `playwright:visual` | screenshot 촬영 후 시각적 확인 | 레이아웃, 색상, 정렬, 애니메이션 등 눈으로만 확인 가능한 것 |

예시:
```json
"completion_criteria": [
  { "criterion": "프로덕션 빌드 통과", "verify": "bash:npm run build", "met": false },
  { "criterion": "타입 체크 통과", "verify": "bash:npx tsc --noEmit", "met": false },
  { "criterion": "score 계산이 판정별로 차등 적용된다", "verify": "test", "met": false },
  { "criterion": "shared에서 games를 import하지 않는다", "verify": "test", "met": false },
  { "criterion": "허브에서 게임 카드가 2개 렌더링된다", "verify": "playwright:dom", "met": false },
  { "criterion": "게임 카드가 그리드로 정렬된다", "verify": "playwright:visual", "met": false },
  { "criterion": "로그인 버튼 클릭 시 OAuth 팝업이 열린다", "verify": "playwright:dom", "met": false },
  { "criterion": "다크모드 전환 시 배경·텍스트 색상이 반전된다", "verify": "playwright:visual", "met": false }
]
```

**verify 선택 기준** (우선순위 순):
1. CLI 한 줄이면 `bash:{command}`
2. 코드로 검증 가능하면 `test`
3. 브라우저 DOM 구조로 확인 가능하면 `playwright:dom`
4. 눈으로만 확인 가능하면 `playwright:visual`

Bad: verify 없이 criterion만 적는 것

## 실행 절차

### Step 1: 컨텍스트 수집

1. 현재 프로젝트의 CLAUDE.md, .claude/rules/*.md 읽기. **Why**: 빌드 명령어, 컨벤션, 의존 방향 등 plan에 반영할 제약사항 파악
2. 관련 코드 탐색 — Agent(Explore) 사용하여 기존 패턴 파악
3. progress.json이 있으면 읽어서 기존 features의 decisions/caveats 확인

### Step 2: Affected Files 파악

- 변경/생성할 파일 목록을 실제 프로젝트 구조 탐색 후 결정. **Why**: 추측한 경로는 구현 시 혼란을 만든다
- MODIFY/DELETE: Glob/Grep으로 확인한 경로만 기재
- CREATE: 부모 디렉토리가 존재하는지 확인. 새 디렉토리가 필요하면 기존 구조 컨벤션과 함께 명시

### Step 3: progress.json에 feature 생성

progress.json이 없으면 `{ "features": [] }`로 생성한다. 기존 파일이 있으면 features 배열에 append한다.

**같은 id의 feature가 이미 존재하면** 덮어쓰지 않고 AskUserQuestion으로 확인한다 (덮어쓰기 / 별도 id / 취소).

feature 객체를 위 스키마에 맞게 작성한다:
- **goal**: 도메인 언어로 "무엇을 왜 만드는지" 한 줄
- **decisions**: Step 1-2에서 파악한 설계 판단. what + why 필수
- **tasks**: Affected Files 기반으로 commit 가능한 단위로 분할. task 이름에 파일명이 아닌 작업 의도를 기술
- **completion_criteria**: 작성 규칙 섹션 참조
- **caveats**: Step 1에서 발견한 함정, 기존 feature의 관련 caveats

### Step 4: Plan 검증 (evaluator-plan 에이전트)

`evaluator-plan` 에이전트를 호출하여 생성된 feature를 검증한다. **Why**: 자가 검증은 anchoring bias — 작성자와 검증자를 분리해야 품질이 올라간다.

에이전트 프롬프트:
```
프로젝트 루트: {root}
대상 feature id: {id}
원래 사용자 요청: {$ARGUMENTS 원문}

evaluator-plan 에이전트의 절차에 따라 검증하고 결과를 출력하라.
```

- VERDICT가 PASS면 plan 완료
- VERDICT가 FAIL이면 FIXES의 수정 지시에 따라 feature를 수정한 뒤 다시 evaluator-plan을 호출
