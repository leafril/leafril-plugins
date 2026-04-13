---
name: plan
description: 기능 설명을 받아 progress/{feature-id}.json에 feature를 생성한다. 제품 동작 스펙과 Completion Criteria 포함. /plan, 새 기능 구현 전 계획 수립 시 사용.
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

- 이 skill은 **제품 동작 스펙**을 만든다. 코드 레벨 설계(클래스 분할, 메서드 시그니처, 파일 구조)는 implement의 몫이다. **Why**: plan이 구현 디테일까지 결정하면 implement가 판단할 여지가 없어진다. "무엇이 동작해야 하는지"만 정의하고, "어떻게 구현할지"는 implement에게 위임한다
- Completion Criteria가 없으면 plan이 아니다. **Why**: 평가 단계가 이 기준으로만 채점한다 — 기준이 없으면 평가 자체가 불가능
- 코드를 작성하지 않는다 — 구조와 방향만 정한다. **Why**: plan과 implement를 분리해야 scope creep을 방지하고 사용자가 방향을 검토할 기회가 생긴다
- Plan이 확정되기 전에 구현을 시작하지 않는다. **Why**: Sprint Contract — 합의 없는 구현은 되돌리기 비용이 크다

# Plan — Product Spec Generator

기능 설명을 받아 `progress/{feature-id}.json`에 feature 객체를 생성한다.
**제품 컨텍스트와 high-level 기술 방향**에 집중하며, 상세 구현 설계는 포함하지 않는다.
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
  "goal": "도메인 언어로 '무엇을 왜 만드는지' 한 줄 — 구현 세부사항(클래스명, 파일명) 금지",
  "decisions": [
    { "what": "아키텍처/제품 수준 결정", "why": "이유" }
  ],
  "tasks": [
    {
      "task": "기능 단위 작업 — 동작을 기술, 구현 방법은 생략",
      "criteria": [
        {
          "criterion": "이 task 완료 시점에 만족되어야 할 기준",
          "status": "PENDING",
          "evidence": null
        }
      ]
    }
  ],
  "invariants": [
    {
      "criterion": "feature 전체에 걸친 횡단 기준 (빌드/타입/아키텍처)",
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

task의 "완료 여부"도 별도 `done` 필드로 저장하지 않는다. `criteria[].status`의 3단계 전이로 파생:

```
PENDING → DONE → PASS / FAIL / SKIP
 (plan)   (implement)   (evaluator)
```

- **구현 완료 task** = `task.criteria.every(c => c.status !== "PENDING")`
- **검증 완료 task** = `task.criteria.every(c => c.status === "PASS" || c.status === "SKIP")`
- **feature 완료** = 모든 task 검증 완료 + 모든 `invariants[].status`가 PASS/SKIP + `evaluation.convention_violations.length === 0`
- **다음 수행할 task** = 첫 번째 `"PENDING"` criteria가 있는 task

### criteria 작성 규칙

각 criterion은 **무엇이 참이어야 하는지**(What)만 기술한다. **어떻게 확인할지**(How)는 evaluator가 criterion 텍스트를 보고 결정한다.

> "Grade what the agent produced, not the path it took." — Anthropic, Demystifying Evals

#### task-level criteria vs invariants — 어디에 둘 것인가

Criterion을 작성할 때마다 "이게 특정 task가 끝났을 때만 검증 의미가 있는가, 아니면 feature 전체에 걸쳐 언제나 참이어야 하는가"를 판단한다.

- **`tasks[].criteria`** — 해당 task의 완료를 증명하는 기준. task별로 1~3개가 일반적.
  - 예: "로그인 버튼 클릭 시 OAuth 팝업이 열린다" → task "OAuth 로그인 지원"에 귀속
  - 예: "판정별 차등 점수가 적용되고 콤보 시 배수가 올라간다" → task "점수 계산"에 귀속
- **`invariants`** — task에 귀속되지 않는 횡단 기준. evaluator가 feature 완료 시 검증한다.
  - 예: "프로덕션 빌드가 통과한다", "타입 체크가 통과한다", "기존 모듈의 공개 인터페이스가 변경되지 않는다"
  - 귀속 여부 판단법: "이 기준이 깨지면 어느 task를 탓해야 하는가?" 답이 명확하면 그 task의 criteria. "전부"나 "모름"이면 invariants.
  - UI 렌더링·상호작용에 묶인 기준은 거의 항상 task-level이다.

#### 필수 규칙

- **모든 task는 최소 1개의 criterion을 가져야 한다.** `criteria: []`는 금지. **Why**: task의 "완료" 정의가 파생 가능해야 `done` 필드 없이 상태를 추적할 수 있다.
- **criterion 문자열은 정량적이어야 한다.** "자연스럽다", "올바르다" 같은 주관적 표현 금지. 입력/출력 쌍 또는 관측 가능한 상태로 기술.
- **criterion은 검증 수단을 포함하지 않는다.** "테스트로 확인", "빌드 명령어로 검증" 같은 How 표현 금지. What만 기술한다.

예시 배치:
```json
"tasks": [
  {
    "task": "판정별 점수 계산과 콤보 시스템",
    "criteria": [
      { "criterion": "PERFECT/GREAT/GOOD/MISS 각 판정에 차등 점수�� 적용된다", "status": "PENDING", "evidence": null },
      { "criterion": "콤보 연속 시 배수가 올라가고, 타임아웃 경과 시 리셋된다", "status": "PENDING", "evidence": null }
    ]
  },
  {
    "task": "허브에 게임 카드 렌더링",
    "criteria": [
      { "criterion": "허브 화면에 게임 카드가 2개 렌더링된다", "status": "PENDING", "evidence": null },
      { "criterion": "게임 카드가 그리드로 정렬된다", "status": "PENDING", "evidence": null }
    ]
  }
],
"invariants": [
  { "criterion": "프로덕션 빌드가 통과한다", "status": "PENDING", "evidence": null },
  { "criterion": "타입 체크가 통과한다", "status": "PENDING", "evidence": null },
  { "criterion": "기존 모듈의 공개 인터페이스가 변경되지 않는다", "status": "PENDING", "evidence": null }
]
```

**behavioral > structural 원칙**: criterion이 증명해야 할 것은 "무엇이 존재하는가"가 아니라 "무엇이 작동하는가"다.

- ❌ **Structural only (지양)**: "src/foo.ts 파일이 존재한다", "useFoo가 export된다" — 존재만 확인. 작동 여부를 증명하지 못한다.
- ✅ **Behavioral**: "PERFECT 판정 시 100점이 반환된다", "허브에서 게임 카드가 2개 렌더링된다"

**리팩토링 feature**에서는 이 원칙이 특히 중요하다. 파일 이동과 식별자 제거만 확인해선 "리팩토링 후에도 동작하는가"를 증명할 수 없다. 리팩토링 feature는 각 task에 **최소 1개 이상의 behavioral criterion**을 포함시켜 기존 동작의 회귀를 막는다.

**status / evidence 필드**: 처음 작성 시 모두 `"PENDING"` / `null`. implement가 task 완료 시 `"DONE"`으로 갱신하고, evaluator가 검증 후 `"PASS"` | `"FAIL"` | `"SKIP"`으로 덮어쓴다. Plan skill은 status/evidence를 건드리지 않는다.

Bad:
- `tasks[].criteria`를 빈 배열로 두는 것
- criterion에 검증 수단을 포함하는 것 (예: "테스트로 확인한다", "bash:npm run build")
- criterion을 task와 무관하게 최상위에 모으는 것 (이전 구조의 `completion_criteria`)
- UI 렌더링·상호작용 기준을 `invariants`에 두는 것
- **structural only criteria로 task를 덮는 것** — 로직 변경 task라면 반드시 behavioral criterion을 포함한다.

## 실행 절차

### Step 1: 컨텍스트 수집

1. 현재 프로젝트의 CLAUDE.md, .claude/rules/*.md 읽기. **Why**: 아키텍처 제약, 의존 방향 등 plan에 반영할 제약사항 파악
2. 관련 코드 탐색 — Agent(Explore) 사용하여 기존 동작과 제약 파악. **주의**: 파일 구조나 클래스 설계를 파악하는 게 아니라, 현재 제품이 어떻게 동작하는지, 어떤 제약이 있는지를 파악하는 것
3. `progress/` 디렉토리의 기존 feature 파일들이 있으면 읽어서 기존 features의 decisions/caveats 확인

### Step 2: feature-id 결정

위 "id 생성 절차"를 따라 후보를 만들고 사용자에게 확인한다.

1. `TZ=Asia/Seoul date +%Y%m%d`로 오늘 KST 날짜 획득
2. `git rev-parse --abbrev-ref HEAD`로 현재 브랜치명 확인
3. 브랜치명이 `{타입}/{설명}` 형식이면 설명 부분 추출, 아니면 사용자 요청 텍스트에서 도메인 설명 추출
4. `{날짜}-{설명}`으로 후보 조합 후 **feature-id 규칙**에 맞는지 검증
5. `progress/{feature-id}.json`이 이미 존재하면 AskUserQuestion으로 충돌 처리
6. 확정된 id를 사용자에게 확인 후 다음 단계로

### Step 3: progress/{feature-id}.json 생성

`progress/` 디렉토리가 없으면 생성하고, `.gitignore` 파일이 없으면 `*` 내용으로 생성한다.

`progress/{feature-id}.json` 파일을 생성한다. feature 객체를 위 스키마에 맞게 작성한다:
- **goal**: 도메인 언어로 "무엇을 왜 만드는지" 한 줄. 구현 세부사항(클래스명, 파일명, 함수명) 금지
- **decisions**: Step 1에서 파악한 **아키텍처/제품 수준** 판단. what + why 필수. 코드 레벨 설계(클래스 분할, 메서드 시그니처, 파일 구조)는 포함하지 않는다
- **tasks**: **기능 단위**로 분할. task 이름은 "무엇이 동작하는지"를 기술. 각 task에 완료를 증명하는 `criteria` 배열을 최소 1개 이상 붙인다 (criteria 작성 규칙 참조)
- **invariants**: 빌드, 타입 체크, 아키텍처 불변 등 특정 task에 귀속되지 않는 횡단 기준. 없으면 빈 배열
- **caveats**: Step 1에서 발견한 제약과 함정. 구현 디테일이 아닌 **제품/아키텍처 수준** 제약만
- **evaluation**: 초기값 `{ "verdict": null, "convention_violations": [], "recommendations": [] }`. 이후 evaluator가 갱신한다

#### plan이 결정하는 것 vs implement에 위임하는 것

| plan이 결정 | implement에 위임 |
|------------|----------------|
| 무엇이 동작해야 하는지 (What) | 어떻게 구현할지 (How) |
| 아키텍처 방향 (Scene 분리, 상태-프레젠테이션 분리) | 클래스/함수 설계 (Score 클래스 vs 순수 함수) |
| 외부 인터페이스 제약 (v1과 동일한 시그니처 유지) | 내부 구현 구조 (파일 분할, 메서드 이름) |
| 제품 동작 기준 (콤보 타임아웃 시 리셋) | 테스트 전략, 코드 구조 |

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
