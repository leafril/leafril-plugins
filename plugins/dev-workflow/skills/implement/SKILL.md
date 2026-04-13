---
name: implement
description: progress/{feature-id}.json의 feature를 읽고 task 단위로 코드 구현 + 테스트 작성 + 테스트 실행을 수행한다. 기본은 각 task 완료 후 변경 요약을 보고하고 사용자 지시를 기다리는 휴먼 리뷰 게이트 모드. 구현 시작, /implement, 코드 작성 시 사용.
disable-model-invocation: true
argument-hint: "[--all] <feature-id (생략 시 planned feature 자동 선택)>"
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

- Plan에 없는 변경은 하지 않는다. **Why**: scope creep 방지. progress/{feature-id}.json에서 합의된 범위만 구현해야 평가 채점이 유효하다. 추가 작업이 필요하면 사용자에게 먼저 확인
- Plan과 다른 접근이 필요하면 사용자에게 먼저 확인한다. **Why**: Sprint Contract — plan은 사용자와의 합의. 일방적 변경은 합의 위반
- **핵심 루프는 code → test → pass/fix 이다.** task마다 코드 작성 → 테스트 작성 → 테스트 실행 → 통과하면 다음 단계, 실패하면 수정해서 재실행. 이 루프를 벗어나지 않는다
- **기본 모드는 task 1개 완료 후 반드시 멈추고 사용자 지시를 기다린다.** **Why**: 휴먼 리뷰 게이트. task마다 사용자가 변경을 검토해야 잘못된 방향을 조기에 잡을 수 있다. 연속 진행은 `--all` 모드에서만
- **기본 모드에서는 자동 커밋하지 않는다. 사용자가 명시적으로 커밋을 지시할 때만 커밋한다.** **Why**: task 리뷰 중 수정이 나오면 "수정 후 한 번에 커밋"이 깔끔하다. 중간 fixup/amend를 유발하지 않는다. `--all` 모드는 task마다 자동 커밋한다
- **Evaluator를 task마다 자동 호출하지 않는다.** **Why**: evaluator가 매 task 재검증하면 invariants(tsc/lint/build)가 반복 실행돼 낭비다. 사용자가 명시적으로 요청하거나, 모든 task가 끝난 feature 완료 시점에 1회만 호출한다
- **Task 완료 시 `criteria.status`를 `"DONE"`으로 갱신한다.** **Why**: 세션 간 진행 추적. `"DONE"`은 "implement 통과"를 뜻하며, evaluator가 검증 후 `"PASS"` / `"FAIL"` / `"SKIP"`으로 덮어쓴다
- behavioral criterion이 있는 task에서는 반드시 테스트를 작성한다. **Why**: 평가 단계는 테스트를 실행만 한다. 테스트가 없으면 해당 criterion은 자동 FAIL
- 테스트 작성 시 `references/test-rules-common.md` + 프로젝트 언어의 `references/test-rules-{lang}.md`를 모두 읽고 규칙을 따른다. **Why**: 평가 단계의 evaluator-test가 같은 규칙으로 품질을 검증한다. 규칙을 따르지 않으면 FAIL
- 컨벤션은 프로젝트 CLAUDE.md 기준. **Why**: 평가 단계에서 컨벤션 위반도 채점한다

# Implement — Feature Implementation

`progress/{feature-id}.json`의 feature를 **task 단위 TDD 루프**로 구현한다.

**핵심 루프** (task 1개 기준):
```
코드 작성 → 테스트 작성 → 테스트 실행
  ├─ PASS → (기본 모드) 변경 요약 보고 → 멈춤
  │        (--all 모드) 자동 커밋 → 다음 task
  └─ FAIL → 구현 수정 → 테스트 재실행 (루프)
```

## 입력 파싱

`$ARGUMENTS`를 파싱한다. `--all` 플래그 + feature id(선택). feature id 생략 시 `progress/` 디렉토리를 스캔하여 미완료 tasks가 있는 feature를 자동 선택한다. 여러 개면 AskUserQuestion으로 선택.

```
/implement                    # 기본 모드, planned feature 자동 선택, 다음 미완료 task 1개 수행
/implement react-migration    # 기본 모드, 특정 feature id 지정
/implement --all              # 일괄 모드, 모든 미완료 task 연속 수행
/implement --all react-migration
```

### 실행 모드

| 모드 | 플래그 | Task 완료 후 동작 | 커밋 |
|------|--------|-------------------|------|
| **단계별 (기본)** | 없음 | 변경 요약 보고 → 멈춤 → 사용자 지시 대기 | 사용자가 "커밋" 지시 시 |
| **일괄** | `--all` | 자동으로 다음 미완료 task 진행 | task 완료 시 자동 커밋 |

두 모드 모두 **per-task evaluator 자동 호출은 하지 않는다**. evaluator는 feature 완료 시점(또는 사용자 명시 요청 시)에만 1회 호출된다.

`--all` 사용 시 주의: 사용자 리뷰가 없으므로 plan이 충분히 구체적이고 단순 반복에 가까운 feature에만 권장. 도중 hook/빌드 실패 또는 plan 전제 오류가 발견되면 **즉시 멈추고 사용자에게 보고**한다.

### 예시: 기본 모드 루프

```
Task 1: 모듈 스캐폴딩 생성
  → 코드 작성 → 테스트 작성 → 테스트 PASS
  → 변경 요약 보고 → 멈춤
    사용자: "다음"
  → Task 2 진행 (커밋 없이)

Task 2: 핵심 로직 구현
  → 코드 작성 → 테스트 작성 → 테스트 FAIL → 구현 수정 → 재실행 → PASS
  → 변경 요약 보고 → 멈춤
    사용자: "커밋하고 다음"
  → commit → Task 3 진행

Task 3: API 엔드포인트 연결
  → 코드 작성 → 테스트 작성 → PASS → 변경 요약 보고 → 멈춤
    사용자: "응답 형식 X로 수정해"
  → 수정 → 테스트 재실행 → PASS → 재보고 → 멈춤
    사용자: "커밋"
  → commit → (대기)
    사용자: "끝"
  → Step 5 feature 완료 처리 → evaluator 1회 호출
```

### 예시: `--all` 모드 루프

```
Task 1: 코드 → 테스트 → PASS → 자동 커밋 → Task 2
Task 2: 코드 → 테스트 → FAIL → 수정 → PASS → 자동 커밋 → Task 3
Task 3: 코드 → 테스트 → PASS → 자동 커밋 → (마지막 task)
→ Step 5 evaluator 1회 호출 → 완료 보고
```

### 예시: Plan 범위 판단

- task "목록 조회 API 구현"을 위해 공통 유틸에 헬퍼 함수가 필요 → **범위 내** (task 완수에 직접 필요)
- 같은 task를 구현하면서 옆에 있는 무관한 함수의 변수명 정리 → **범위 밖** (plan에 없는 변경)

## 실행 절차

### Step 1: Plan 읽기

1. `progress/{feature-id}.json` 파일에서 feature 읽기 (파일이 없으면 중단하고 사용자에게 보고)
2. **종료 조건 판정** — 아래 식이 모두 참이면 feature 완료 상태. 실행 중단.
   - 모든 `tasks[].criteria[].status`가 `"DONE"`, `"PASS"`, 또는 `"SKIP"`
   - 모든 `invariants[].status`가 `"DONE"`, `"PASS"`, 또는 `"SKIP"`
   - `evaluation.convention_violations.length === 0` (evaluation이 아직 비어 있으면 이 조건은 건너뛰고 아래 3번으로 진행)
3. CLAUDE.md, .claude/rules/*.md 읽기 (컨벤션 파악)
4. behavioral criterion(로직, 상태 전환, 데이터 흐름 등 코드로 검증 가능한 기준)이 하나라도 있으면 **테스트 규칙 파일 두 개를 모두 읽는다**:
   - `references/test-rules-common.md` — 언어 무관 원칙 (필수)
   - 프로젝트 언어에 맞는 `references/test-rules-{lang}.md`:
     * Kotlin/Java (루트에 `build.gradle*` 또는 `pom.xml`) → `references/test-rules-kotlin.md`
     * TypeScript/JavaScript (루트에 `package.json` + `tsconfig.json` 또는 `*.ts`/`*.tsx`) → `references/test-rules-typescript.md`
   - common.md의 §1~§7을 먼저 읽고, 언어 파일에서 해당 §의 구체 적용(§K* / §T*)을 확인한다
   - 규칙 파일 경로는 이 스킬 기준 상대 경로 (`../../references/test-rules-*.md`)

### Step 2: Task 핵심 루프 (code → test → pass/fix)

**"미완료 task" 정의** — `task.criteria` 중 `status`가 `"PENDING"`인 것이 하나라도 있는 task. `tasks` 배열을 순서대로 훑어 첫 번째 미완료 task를 현재 작업 대상으로 삼는다. `"DONE"` 이상(`"DONE"`, `"PASS"`, `"SKIP"`)은 모두 "완료"로 간주한다.

현재 task에 대해:

```
1. 코드 작성
2. 테스트 작성 (해당 task에 behavioral criterion이 있으면 필수)
   - **behavioral criterion 판단**: criterion이 로직, 상태 전환, 데이터 흐름, 출력값 등
     코드의 동작을 기술하면 behavioral. 빌드/타입 체크 같은 환경 검증은 non-behavioral.
   - Step 1에서 읽은 rules 파일의 규칙을 따른다. 아래 § 번호는 `test-rules-common.md` 기준이며, 언어 파일의 §K*/§T*는 해당 §의 구체 적용이다
   - common §1 코드 유형 분류 → 적절한 테스트 전략 선택
   - common §2 테스트하지 않는 것 → 불필요한 테스트 제외 (언어별 구체 예시는 §K1/§T1)
   - common §3 테스트 스타일 우선순위 → 출력 > 상태 > 통신
   - common §5 mock 규칙 → managed 실제 사용, unmanaged만 mock (언어별 도구 사용법은 §K2/§T2)
   - common §6 구조 규칙 → 이름, GWT, fixture (언어별 관용구는 §K3/§T3)
3. 테스트 실행
4. 결과 판정:
   - PASS → 루프 탈출. (기본 모드) Step 3 보고로, (--all 모드) Step 4 자동 커밋 후 Step 2 반복
   - FAIL → 구현(또는 테스트) 수정 → 3번으로 돌아가 재실행. 통과까지 반복
```

**테스트 위치**: 프로젝트의 기존 테스트 컨벤션을 따른다. 없으면 `tests/` 또는 소스 파일 옆 `*.test.*` 패턴.

**테스트가 반복해서 실패할 때**: 같은 FAIL 원인으로 3회 연속 고쳤는데도 통과 못 하면 루프를 멈추고 사용자에게 "FAIL 상태 + 추정 원인"을 보고한 뒤 지시를 받는다. FAIL을 숨기고 다음 단계로 넘어가지 않는다.

**non-behavioral criterion만 있는 task**: 빌드 통과, 타입 체크 같은 환경 검증만 있는 task는 테스트 작성이 불필요하다. 코드 작성 후 해당 명령을 실행하여 통과를 확인한다.

**Task 완료 시 status 갱신**: 현재 task의 모든 테스트가 통과하면(루프 탈출 직전), 해당 task의 `criteria[].status`를 모두 `"DONE"`으로 갱신한다. `progress/{feature-id}.json` 파일을 Edit/Write로 업데이트한다. `evidence` 필드는 건드리지 않는다 (evaluator가 검증 시 채움).

**이 단계에서 하지 않는 것**:
- Evaluator 호출 (Step 5에서 명시 요청 또는 feature 완료 시점에만)
- `criteria.status`를 `"PASS"` / `"FAIL"` / `"SKIP"`으로 설정 (evaluator만 가능. implement는 `"DONE"`까지만)
- `criteria.evidence` 갱신 (evaluator만 건드림)
- 기본 모드에서 다음 task 자동 진행 (Step 3에서 멈춤)

### Step 3: 변경 요약 보고 + 사용자 지시 대기 (기본 모드 전용)

> `--all` 모드에서는 이 Step을 건너뛰고 Step 4(자동 커밋) → Step 2(다음 task) 로 넘어간다.

현재 task의 테스트가 통과하면 다음을 사용자에게 보고하고 **멈춘다**:

1. **수행한 task** — plan의 task 문장 인용
2. **변경된 파일 목록** — new / modified / deleted
3. **주요 결정 요약** — 1~3줄
4. **테스트 결과** — 작성한 테스트가 있으면 실행 결과
5. **남은 task 수** — 진행 상황

보고 후 **사용자 지시를 기다린다**. 자동으로 다음 task로 진행하지 않는다.

사용자 지시 해석 (자연어로 판정, 예시는 가이드):

| 사용자 발화 예시 | 동작 |
|---|---|
| "커밋", "커밋해", "commit" | Step 4 — 현재 변경을 하나의 커밋으로 묶음. 이후 계속 대기 |
| "다음", "next", "다음 task" | Step 2 반복 — 다음 미완료 task 진행. 커밋은 하지 않음 |
| "커밋하고 다음", "커밋 후 다음" | Step 4 commit → Step 2 진행 |
| "X를 Y로 수정해" 등 구체적 지시 | 지시 반영 → Step 3 재보고 → 다시 대기 |
| "evaluator 돌려줘", "평가해" | Step 5 evaluator 호출 (명시적) |
| "끝", "완료", "feature 끝" | Step 5 feature 완료 처리 (evaluator 1회 호출) |

애매하면 AskUserQuestion으로 확인한다. 추측해서 진행하지 않는다.

### Step 4: 커밋

커밋 트리거:
- **기본 모드**: 사용자가 명시적으로 커밋을 지시했을 때만
- **`--all` 모드**: 각 task의 Step 2 루프가 PASS로 끝나면 자동으로 실행

절차:
1. `git status`로 현재 변경 확인
2. `git add`로 현재 task 범위의 파일만 스테이지 (다른 task의 미커밋 변경이 섞여 있으면 기본 모드는 사용자에게 확인, `--all` 모드는 멈추고 보고)
3. 커밋 메시지 초안 작성 — plan의 task 설명을 제목으로, 간단한 본문
4. **기본 모드**: 초안을 사용자에게 보여주고 승인 받음. 수정 지시 있으면 반영 후 재확인. **`--all` 모드**: 초안을 그대로 사용
5. `git commit` 실행 → commit hash 보고
6. **기본 모드**: 커밋 완료 후 다시 대기 (사용자가 "다음"을 지시하지 않으면 그대로 멈춤). **`--all` 모드**: Step 2로 복귀하여 다음 미완료 task 진행

`--no-verify` 등 hook 우회 금지. hook 실패 시 원인 파악 후 재시도.

### Step 5: Feature 완료 처리 (evaluator 1회 호출)

사용자가 "완료"/"끝"을 지시하거나 명시적으로 evaluator 호출을 요청하면, evaluator를 호출한다.

```
Agent(subagent_type="evaluator") with prompt:
  "Feature ID: {feature_id}, Project root: {root}.
   evaluator 에이전트 절차에 따라 평가를 수행하라."
```

evaluator는 `progress/{feature-id}.json`의 각 criterion `status`/`evidence`와 `evaluation` 필드를 갱신한다. 결과 대응:

- **모두 PASS** → 사용자에게 완료 보고
- **일부 FAIL** → FAIL 항목을 사용자에게 제시, `evaluation` 필드의 수정 방향 요약 → 사용자 지시 대기 → 수정 반영 → 사용자가 재평가 요청 시 evaluator 재호출 (최대 3회, 초과 시 AskUserQuestion)

## 경계 사례

- **테스트 프레임워크가 없는 프로젝트에서 behavioral criterion을 만났을 때**: 프로젝트에 적합한 테스트 러너를 설치하고 최소 설정을 추가한다. 설치 전 AskUserQuestion으로 테스트 프레임워크 선택을 확인한다.
- **task 진행 중 plan 전제가 틀렸음을 발견했을 때** (예: 예상 API가 없음, 의존성 비호환): 구현을 중단하고 AskUserQuestion으로 사용자에게 보고한다. 임의로 plan을 우회하지 않는다.
- **plan 범위 판단이 애매할 때** (예: 구현에 필요한 소규모 리팩토링): task 완수에 직접 필요한 최소 변경만 허용. "하는 김에" 식의 정리는 범위 밖.
- **테스트가 계속 FAIL할 때**: 3회 시도해도 통과 못 하면 Step 3으로 진행해 "테스트 FAIL 상태 + 원인 추정"을 사용자에게 보고하고 지시를 받는다. FAIL을 숨기고 다음 task로 넘어가지 않는다.

## 하지 않는 것

- **기본 모드에서 task 1개 수행 후 자동으로 다음 task 진행** (휴먼 리뷰 게이트 위반). `--all` 모드에서만 허용
- **기본 모드에서 자동 커밋** (사용자 지시 후에만). `--all` 모드에서만 자동 커밋
- **Per-task evaluator 자동 호출** (두 모드 모두). evaluator는 사용자 명시 요청 또는 feature 완료 시점에만 1회
- **테스트 작성 없이 behavioral criterion task 넘기기**. behavioral criterion이 있으면 반드시 테스트 작성 후 통과 확인
- Plan 범위 밖의 리팩토링, 코드 정리
- 컨벤션 외 주관적 개선 ("이 변수명이 더 나을 것 같다")
- PASS/FAIL 판정, 컨벤션 검증 리포트 (evaluator의 책임)
- criterion의 status를 `"PASS"` / `"FAIL"` / `"SKIP"`으로 설정 (evaluator의 책임. implement는 `"DONE"`까지만)
- criterion의 evidence 갱신 (evaluator의 책임)
