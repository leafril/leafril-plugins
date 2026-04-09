---
name: implement
description: progress.json의 feature를 읽고 코드 구현 + 테스트 작성 + 테스트 실행을 수행한다. 구현 시작, /implement, 코드 작성 시 사용.
disable-model-invocation: true
argument-hint: [--all] <feature-id (생략 시 planned feature 자동 선택)>
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

## Gotchas

- Plan에 없는 변경은 하지 않는다. **Why**: scope creep 방지. progress.json에서 합의된 범위만 구현해야 평가 채점이 유효하다. 추가 작업이 필요하면 사용자에게 먼저 확인
- Plan과 다른 접근이 필요하면 사용자에게 먼저 확인한다. **Why**: Sprint Contract — plan은 사용자와의 합의. 일방적 변경은 합의 위반
- `verify: "test"` criteria가 있으면 반드시 테스트를 작성한다. **Why**: 평가 단계는 테스트를 실행만 한다. 테스트가 없으면 해당 criterion은 자동 FAIL
- 테스트 작성 시 `references/rules-{lang}.md`를 읽고 규칙을 따른다. **Why**: 평가 단계의 evaluator-test가 같은 규칙으로 품질을 검증한다. 규칙을 따르지 않으면 FAIL
- 컨벤션은 프로젝트 CLAUDE.md 기준. **Why**: 평가 단계에서 컨벤션 위반도 채점한다

# Implement — Feature Implementation

progress.json의 feature를 읽고 구현한다. 코드 + 테스트 + 실행까지 이 skill의 책임.

## 입력 파싱

`$ARGUMENTS`를 feature id로 처리한다. 생략 시 미완료 tasks가 있는 feature를 자동 선택한다. 여러 개면 AskUserQuestion으로 선택.

```
/implement                    # planned feature 자동 선택, 다음 미완료 task 1개 수행
/implement react-migration    # 특정 feature id 지정, 다음 미완료 task 1개 수행
/implement --all              # 모든 미완료 tasks 연속 수행
/implement --all react-migration
```

### 실행 모드

| 모드 | 플래그 | 동작 |
|------|--------|------|
| **단계별** (기본) | 없음 | 다음 미완료 task 1개만 수행 후 종료 |
| **일괄** | `--all` | 모든 미완료 tasks를 순서대로 연속 수행 |

### 예시: Task 루프

```
Task 1: 모듈 스캐폴딩 생성
  → 코드 작성 → 테스트 없음 → evaluator 호출 → PASS → commit → 다음
Task 2: 핵심 로직 구현
  → 코드 작성 → 테스트 작성 → 테스트 FAIL → 수정 → 테스트 PASS
  → evaluator 호출 → PASS → commit → 다음
Task 3: API 엔드포인트 연결
  → 코드 작성 → evaluator 호출 → FAIL (응답 형식 불일치)
  → evaluation-report.md 읽고 수정 → evaluator 재호출 → PASS → commit → 다음
```

### 예시: Plan 범위 판단

- task "목록 조회 API 구현"을 위해 공통 유틸에 헬퍼 함수가 필요 → **범위 내** (task 완수에 직접 필요)
- 같은 task를 구현하면서 옆에 있는 무관한 함수의 변수명 정리 → **범위 밖** (plan에 없는 변경)

## 실행 절차

### Step 1: Plan 읽기

1. progress.json에서 대상 feature 읽기
2. feature가 없거나 모든 tasks가 완료 + 모든 criteria가 met이면 중단
3. CLAUDE.md, .claude/rules/*.md 읽기 (컨벤션 파악)
4. `verify: "test"` criteria가 있으면 프로젝트 언어에 맞는 테스트 규칙 파일을 읽는다:
   - Kotlin/Java 프로젝트 → `references/rules-kotlin.md`
   - TypeScript/JavaScript 프로젝트 → `references/rules-typescript.md`
   - 규칙 파일 경로는 이 스킬 기준 상대 경로 (`../../references/rules-{lang}.md`)

### Step 2: Task 실행 (구현 → 테스트 → 평가 → 커밋)

- **기본 모드**: 첫 번째 미완료 task 1개만 수행 후 종료
- **`--all` 모드**: 모든 미완료 tasks를 순서대로 진행

```
for each task (기본 모드에서는 1회만):
  1. 코드 작성
  2. 테스트 작성 (verify:"test" criteria 관련이면)
     - Step 1에서 읽은 rules 파일의 규칙을 따른다
     - §1 코드 유형 분류 → 적절한 테스트 전략 선택
     - §2 테스트하지 않는 것 → 불필요한 테스트 제외
     - §3 테스트 스타일 우선순위 → 출력 > 상태 > 통신
     - §5 mock 규칙 → managed 실제 사용, unmanaged만 mock
     - §6 구조 규칙 → 이름, GWT, fixture, DI
  3. 테스트 실행
     FAIL → 구현 수정 → 재실행 (테스트 통과까지)
  4. evaluator 호출 (Step 3)
     FAIL → 수정 → 재평가 (최대 3회, 초과 시 AskUserQuestion)
     PASS → commit
```

**테스트 위치**: 프로젝트의 기존 테스트 컨벤션을 따른다. 없으면 `tests/` 또는 소스 파일 옆 `*.test.*` 패턴.

### Step 3: Evaluator 호출

테스트 통과 후 (또는 테스트 불필요 시 코드 작성 후) evaluator를 직접 호출한다.

```
Agent(subagent_type="evaluator") with prompt:
  "Feature ID: {feature_id}, Project root: {root}.
   evaluator 에이전트 절차에 따라 평가를 수행하라."
```

`evaluation-report.md`가 생성되면 읽고 대응한다:

- **PASS** → commit → 다음 task
- **FAIL** → 리포트의 수정 방향을 참고하여 수정 → evaluator 재호출 (최대 3회, 초과 시 AskUserQuestion)

### Step 4: 완료 보고

모든 tasks 완료 + evaluator PASS 후 사용자에게 보고한다.

## 경계 사례

- **테스트 프레임워크가 없는 프로젝트에서 `verify: "test"` criteria를 만났을 때**: 프로젝트에 적합한 테스트 러너를 설치하고 최소 설정을 추가한다. 설치 전 AskUserQuestion으로 테스트 프레임워크 선택을 확인한다.
- **task 진행 중 plan 전제가 틀렸음을 발견했을 때** (예: 예상 API가 없음, 의존성 비호환): 구현을 중단하고 AskUserQuestion으로 사용자에게 보고한다. 임의로 plan을 우회하지 않는다.
- **plan 범위 판단이 애매할 때** (예: 구현에 필요한 소규모 리팩토링): task 완수에 직접 필요한 최소 변경만 허용. "하는 김에" 식의 정리는 범위 밖.

## 하지 않는 것

- Plan 범위 밖의 리팩토링, 코드 정리
- 컨벤션 외 주관적 개선 ("이 변수명이 더 나을 것 같다")
- PASS/FAIL 판정, 컨벤션 검증 리포트 (evaluator의 책임)
- completion_criteria.met 갱신 (evaluator의 책임)
