---
name: plan
description: 기능 설명을 받아 progress/{feature-id}.json에 feature를 생성한다. Completion Criteria 포함. 구현 계획, 코드 레벨 설계, /plan, 새 기능 구현 전 계획 수립 시 사용.
argument-hint: <기능 설명>
allowed-tools:
  - AskUserQuestion
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

## Gotchas

- 이 skill은 **코드 레벨 구현 계획**을 세운다. 기획(what to build)은 별도 단계에서 다룬다
- Completion Criteria가 없으면 plan이 아니다. **Why**: 평가 단계가 이 기준으로만 채점한다 — 기준이 없으면 평가 자체가 불가능
- 코드를 작성하지 않는다 — 구조와 방향만 정한다. **Why**: plan과 implement를 분리해야 scope creep을 방지하고 사용자가 방향을 검토할 기회가 생긴다
- Plan이 확정되기 전에 구현을 시작하지 않는다. **Why**: Sprint Contract — 합의 없는 구현은 되돌리기 비용이 크다

# Plan — Implementation Plan Generator

기능 설명을 받아 `progress/{feature-id}.json`에 feature 객체를 생성한다.
구현 단계에서 tasks가 수행되고, 평가 단계에서 각 task의 criteria와 feature 전체의 invariants가 채점된다.

## 파일 구조

```
progress/
├── {feature-id}.json      # feature plan + tasks + evaluation
├── {another-feature-id}.json
└── .gitignore              # * (전체 무시)
```

- 각 feature는 독립된 JSON 파일로 관리된다
- `progress/` 디렉토리가 없으면 생성한다
- `.gitignore`가 없으면 `*` 내용으로 생성한다

## 입력 파싱

`$ARGUMENTS`를 기능 설명 텍스트로 처리한다. 인자가 없으면 AskUserQuestion으로 요청한다.

```
/plan 로그인 폼에 OAuth 구글 로그인 버튼 추가
/plan API 응답 캐싱 레이어 추가 — React Query 도입
```

### 요청 범위가 클 때

하나의 요청이 독립적으로 배포/테스트 가능한 여러 기능을 포함하면 feature를 분할한다. **Why**: feature가 크면 criteria가 모호해지고 평가 채점이 부정확해진다.

- **분할 기준**: "이 부분만 머지해도 동작하는가?" — Yes면 별도 feature
- **분할 시**: AskUserQuestion으로 분할안을 제시하고 사용자 확인 후 각각 feature 생성
- **분할하지 않는 경우**: 기능이 크더라도 중간 단계가 단독으로 의미 없으면 하나의 feature로 유지 (tasks로 분할)

### 기존 feature와 기능적으로 겹칠 때

Step 1에서 `progress/` 디렉토리의 기존 feature 파일들을 읽었을 때 새 요청과 기능 범위가 겹치는 기존 feature가 있으면, AskUserQuestion으로 확인한다:
- "기존 feature `{id}`를 확장" — 기존 feature에 tasks/criteria 추가
- "별도 feature로 생성" — 독립적으로 추적
- "기존 feature 대체" — 기존 feature의 tasks가 모두 미완료일 때만 허용

## feature-id 규칙

feature-id는 `progress/{feature-id}.json`의 파일명이 되므로 아래 규칙을 따른다.

### 형식

```
{YYYYMMDD}-{설명}
```

- **YYYYMMDD (필수)**: plan skill 실행 시점의 KST 날짜 (하이픈 없는 8자리 숫자)
  - `TZ=Asia/Seoul date +%Y%m%d`로 생성
  - **Why**: `ls progress/`가 시간순 정렬되어 최근 작업을 한눈에 파악. 같은 도메인 작업이 여러 번 있어도 자연스럽게 구분
- **설명**: 도메인 언어 kebab-case. 무엇을 만드는지 짧게 요약

예시:
```
20260410-tap-sequence-state-refactor
20260410-login-oauth-button
20260411-today-snap-missing-fix
```

### 문자 규칙

- 정규식: `^[0-9]{8}-[a-z][a-z0-9-]*$`
- 길이: 70자 이하
- 연속 하이픈(`--`) 금지, 앞뒤 하이픈 금지
- 대문자 금지

### 의미 규칙 (도메인 자립성)

파일명/클래스명/함수명 등 구현 세부사항을 id에 넣지 않는다. `goal 자립성`과 동일한 원칙.

```
❌ 20260410-state-ts-split             (파일명이 들어감)
❌ 20260410-add-usereducer-hook        (구현 디테일)
✅ 20260410-tap-sequence-state-refactor (도메인)
✅ 20260410-login-oauth                 (도메인)
```

작업 성격(feat/fix/refactor 등)은 id에 강제하지 않는다. 필요하면 설명 끝에 자연스럽게 붙일 수 있다 (예: `...-refactor`, `...-fix`). 작업 성격은 `goal` 필드와 브랜치명에서 이미 명확히 드러나므로 id에 중복할 필요가 없다.

### id 생성 절차

1. `TZ=Asia/Seoul date +%Y%m%d`로 오늘 날짜 획득
2. **설명 생성 우선순위**:
   - (1순위) 현재 git 브랜치명이 `{타입}/{설명}` 형식이면 `{설명}` 부분 사용
     - `refactor/tap-sequence-state` → `tap-sequence-state`
   - (2순위) 브랜치명이 main/dev-* 또는 컨벤션 외면 사용자 요청 텍스트에서 도메인 설명 추출
3. `{날짜}-{설명}`으로 조합
4. 후보 id를 사용자에게 확인 — 수정 원하면 AskUserQuestion으로 직접 입력

### 충돌 처리

`progress/{feature-id}.json`이 이미 존재하면 AskUserQuestion으로 확인:
- **기존 feature 확장** — 기존 파일에 tasks/criteria append
- **별도 id로 생성** — suffix 붙이기 (`-v2`, `-part2` 등)
- **기존 feature 대체** — 기존 feature의 모든 tasks가 미완료일 때만 허용

같은 날 같은 도메인 작업이 재실행되는 드문 경우에만 충돌 가능 (날짜가 달라지면 자동으로 새 id).

## feature JSON 스키마

각 feature는 `progress/{feature-id}.json` 파일로 저장된다. 스키마:

```json
{
  "goal": "맥락 없이 읽어도 뭘 만드는지 알 수 있는 한 줄 요약",
  "decisions": [
    { "what": "최종 결정", "why": "이유" }
  ],
  "tasks": [
    {
      "task": "구체적 작업 단위",
      "criteria": [
        {
          "criterion": "이 task 완료 시점에 만족되어야 할 기준",
          "verify": "bash:{cmd}|test|playwright:dom|playwright:visual",
          "status": "PENDING",
          "evidence": null
        }
      ]
    }
  ],
  "invariants": [
    {
      "criterion": "feature 전체에 걸친 횡단 기준 (빌드/타입/아키텍처)",
      "verify": "bash:{cmd}|test",
      "status": "PENDING",
      "evidence": null
    }
  ],
  "caveats": [
    "구현 시 주의할 함정이나 제약"
  ],
  "evaluation": {
    "verdict": null,
    "convention_violations": [],
    "recommendations": []
  }
}
```

feature id는 파일명(`progress/{feature-id}.json`)이 단일 source of truth이므로 JSON 내부에 중복 저장하지 않는다.

task의 "완료 여부"도 별도 `done` 필드로 저장하지 않는다. 파생 규칙:
- **task 완료** = `task.criteria.every(c => c.status === "PASS" || c.status === "SKIP")`
- **feature 완료** = 모든 task 완료 + 모든 `invariants[].status`가 PASS/SKIP + `evaluation.convention_violations.length === 0`
- **다음 수행할 task** = 첫 번째 "아직 완료 판정이 아닌" task

### criteria 작성 규칙

각 criterion은 `verify` 필드로 검증 방법을 명시한다. 평가 단계에서 이 필드를 보고 기계적으로 실행한다.

| verify 값 | 검증 방법 | 사용 시점 |
|-----------|-----------|-----------|
| `bash:{command}` | 명령어 실행, exit code 0이면 PASS | 빌드, 타입 체크, lint, 테스트 러너 실행 등 **실행/출력**으로 확인 가능한 것 |
| `test` | criterion 기반 테스트 파일 탐색 → 실행 | 로직, 상태 전환, 출력, 데이터 흐름 등 코드로 검증 가능한 것 |
| `playwright:dom` | snapshot + evaluate로 DOM 요소/텍스트/속성/인터랙션 확인 | 실제 렌더 결과, 상호작용 후 상태 변화 |
| `playwright:visual` | screenshot 촬영 후 시각적 확인 | 레이아웃, 색상, 정렬, 애니메이션 등 눈으로만 확인 가능한 것 |

#### task-level criteria vs invariants — 어디에 둘 것인가

Criterion을 작성할 때마다 "이게 특정 task가 끝났을 때만 검증 의미가 있는가, 아니면 feature 전체에 걸쳐 언제나 참이어야 하는가"를 판단한다.

- **`tasks[].criteria`** — 해당 task의 완료를 증명하는 기준. task별로 1~3개가 일반적.
  - 예: "로그인 버튼 클릭 시 OAuth 팝업이 열린다" → task "OAuth 버튼 추가"에 귀속
  - 예: "score 계산이 판정별로 차등 적용된다" → task "점수 계산 로직 구현"에 귀속
- **`invariants`** — task에 귀속되지 않는 횡단 기준. evaluator가 매 task 완료 시마다 재검증한다.
  - 예: "프로덕션 빌드 통과", "타입 체크 통과", "shared에서 games를 import하지 않는다"
  - 귀속 여부 판단법: "이 기준이 깨지면 어느 task를 탓해야 하는가?" 답이 명확하면 그 task의 criteria. "전부"나 "모름"이면 invariants.
- **verify 타입 제약**: invariants는 보통 `bash:` 또는 `test`. `playwright:*`는 특정 화면·상호작용에 묶이므로 거의 항상 task-level이다.

#### 필수 규칙

- **모든 task는 최소 1개의 criterion을 가져야 한다.** `criteria: []`는 금지. **Why**: task의 "완료" 정의가 파생 가능해야 `done` 필드 없이 상태를 추적할 수 있다. 스캐폴딩 같은 자명한 task도 `bash:test -d src/newmodule` 같은 1줄 검증으로 객관화할 수 있다.
- **criterion 문자열은 정량적이어야 한다.** "자연스럽다", "올바르다" 같은 주관적 표현 금지. 입력/출력 쌍 또는 관측 가능한 상태로 기술.

예시 배치:
```json
"tasks": [
  {
    "task": "점수 계산 로직 구현",
    "criteria": [
      { "criterion": "score 계산이 판정별로 차등 적용된다", "verify": "test", "status": "PENDING", "evidence": null }
    ]
  },
  {
    "task": "허브에 게임 카드 렌더링",
    "criteria": [
      { "criterion": "허브에서 게임 카드가 2개 렌더링된다", "verify": "playwright:dom", "status": "PENDING", "evidence": null },
      { "criterion": "게임 카드가 그리드로 정렬된다", "verify": "playwright:visual", "status": "PENDING", "evidence": null }
    ]
  }
],
"invariants": [
  { "criterion": "프로덕션 빌드 통과", "verify": "bash:npm run build", "status": "PENDING", "evidence": null },
  { "criterion": "타입 체크 통과", "verify": "bash:npx tsc --noEmit", "status": "PENDING", "evidence": null },
  { "criterion": "shared에서 games를 import하지 않는다", "verify": "test", "status": "PENDING", "evidence": null }
]
```

**verify 선택 기준**:

먼저 **behavioral > structural 원칙**을 적용한다. criterion이 증명해야 할 것은 "무엇이 존재하는가"가 아니라 "무엇이 작동하는가"다.

- ❌ **Structural only (지양)**: `bash:test -f src/foo.ts`, `bash:grep -c "export const useFoo" ... -eq 1`, `bash:test -d src/newmodule` — 파일·식별자 존재만 확인. 작동 여부를 증명하지 못한다.
- ✅ **Behavioral**: `test` (실제 렌더/상태 전환/출력), `playwright:dom` (DOM 상호작용), `bash:npm test -- useFoo` (테스트 러너 실행)

**리팩토링 feature**에서는 이 원칙이 특히 중요하다. 파일 이동과 식별자 제거만 확인해선 "리팩토링 후에도 동작하는가"를 증명할 수 없다. 리팩토링 feature는 각 task에 **최소 1개 이상의 behavioral criterion**을 포함시켜 기존 동작의 회귀를 막는다 (예: 훅/컴포넌트 렌더 테스트, 상태 전환 테스트).

`bash:test -f` / `bash:grep -c` 같은 존재 체크는 **보조적으로만** 사용한다. 순수 파일 이동/정리 같은 자명한 task에서 1개 정도는 허용되나, 로직 변경 task에서는 반드시 behavioral criterion으로 보완한다.

**우선순위 (behavioral 가능성이 동등하면)**:
1. 코드로 검증 가능하면 `test`
2. 브라우저 렌더·상호작용으로 확인 가능하면 `playwright:dom`
3. 눈으로만 확인 가능하면 `playwright:visual`
4. CLI 한 줄로 **실행 결과** 검증 가능하면 `bash:{command}` (빌드, 타입 체크, 테스트 러너 실행)

**status / evidence 필드**: 처음 작성 시 모두 `"PENDING"` / `null`. evaluator만 `PASS` | `FAIL` | `SKIP`으로 갱신한다. Plan skill은 status/evidence를 건드리지 않는다.

Bad:
- verify 없이 criterion만 적는 것
- `tasks[].criteria`를 빈 배열로 두는 것
- criterion을 task와 무관하게 최상위에 모으는 것 (이전 구조의 `completion_criteria`)
- playwright 계열 criterion을 `invariants`에 두는 것
- **structural only criteria로 task를 덮는 것** (예: `bash:test -f`, `bash:grep -c`만으로 task 완료 판정). 리팩토링 여부만 증명하고 동작 회귀를 증명하지 못한다. 로직 변경 task라면 반드시 behavioral criterion을 포함한다.

## 실행 절차

### Step 1: 컨텍스트 수집

1. 현재 프로젝트의 CLAUDE.md, .claude/rules/*.md 읽기. **Why**: 빌드 명령어, 컨벤션, 의존 방향 등 plan에 반영할 제약사항 파악
2. 관련 코드 탐색 — Agent(Explore) 사용하여 기존 패턴 파악
3. `progress/` 디렉토리의 기존 feature 파일들이 있으면 읽어서 기존 features의 decisions/caveats 확인

### Step 2: Affected Files 파악

- 변경/생성할 파일 목록을 실제 프로젝트 구조 탐색 후 결정. **Why**: 추측한 경로는 구현 시 혼란을 만든다
- MODIFY/DELETE: Glob/Grep으로 확인한 경로만 기재
- CREATE: 부모 디렉토리가 존재하는지 확인. 새 디렉토리가 필요하면 기존 구조 컨벤션과 함께 명시

### Step 3: feature-id 결정

위 "id 생성 절차"를 따라 후보를 만들고 사용자에게 확인한다.

1. `TZ=Asia/Seoul date +%Y%m%d`로 오늘 KST 날짜 획득
2. `git rev-parse --abbrev-ref HEAD`로 현재 브랜치명 확인
3. 브랜치명이 `{타입}/{설명}` 형식이면 설명 부분 추출, 아니면 사용자 요청 텍스트에서 도메인 설명 추출
4. `{날짜}-{설명}`으로 후보 조합 후 **feature-id 규칙**에 맞는지 검증
5. `progress/{feature-id}.json`이 이미 존재하면 AskUserQuestion으로 충돌 처리
6. 확정된 id를 사용자에게 확인 후 다음 단계로

### Step 4: progress/{feature-id}.json 생성

`progress/` 디렉토리가 없으면 생성하고, `.gitignore` 파일이 없으면 `*` 내용으로 생성한다.

`progress/{feature-id}.json` 파일을 생성한다. feature 객체를 위 스키마에 맞게 작성한다:
- **goal**: 도메인 언어로 "무엇을 왜 만드는지" 한 줄
- **decisions**: Step 1-2에서 파악한 설계 판단. what + why 필수
- **tasks**: Affected Files 기반으로 commit 가능한 단위로 분할. task 이름에 파일명이 아닌 작업 의도를 기술. 각 task에 그 task의 완료를 증명하는 `criteria` 배열을 최소 1개 이상 붙인다 (criteria 작성 규칙 참조).
- **invariants**: 빌드, 타입 체크, 아키텍처 불변 등 특정 task에 귀속되지 않는 횡단 기준. 없으면 빈 배열.
- **caveats**: Step 1에서 발견한 함정, 기존 feature의 관련 caveats
- **evaluation**: 초기값 `{ "verdict": null, "convention_violations": [], "recommendations": [] }`. 이후 evaluator가 갱신한다.

### Step 5: Plan 검증 (evaluator-plan 에이전트)

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
