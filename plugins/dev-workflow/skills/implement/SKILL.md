---
name: implement
description: progress/{feature-id}.json의 features를 배열 순서대로 하나씩 구현한다. 기본은 feature 하나 완료 후 사용자 리뷰를 기다리는 휴먼 게이트 모드. /implement, 구현 시작 시 사용.
disable-model-invocation: true
argument-hint: "[--all] [feature-id]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Implement — Feature-by-Feature Loop

`progress/{feature-id}.json`의 `features` 배열을 **순서대로** 하나씩 구현한다.

## 핵심 원칙

- **features 배열 순서 = 구현 순서**. `status: "TODO"`인 첫 항목부터 처리
- **feature 하나 = 구현 단위**. 구현 후 사용자가 리뷰하고 `"DONE"`으로 전환
- **plan에 없는 변경 금지**. 필요하면 사용자에게 먼저 확인
- **plan 전제가 틀렸다고 판단되면 중단 후 보고**. 임의로 plan 우회 금지
- **선행 feature가 필요하다고 판단되면 중단하고 사용자에게 `/plan`으로 선행 feature 작성을 제안**한다. `--all` 모드에서도 동일. 임의로 선행 작업을 시작하거나 /plan을 자동 호출하지 않는다
- **평가는 사람이 한다**. 자동 evaluator 호출 없음

## `implementation.steps` — 세션 간 working state

implement 단계가 관리하는 필드. plan은 건드리지 않는다.

**왜 필요한가**: Claude Code 세션은 메모리를 공유하지 않는다. feature 하나 구현이 여러 세션에 걸칠 때, 다음 세션이 "어디까지 했고 뭘 할 차례인가"를 복구할 유일한 수단. TaskList는 session-scoped라 이 역할을 못 함.

**무엇을 담는가**: 코드/commit/rules/plan 어디로도 복구 불가능한 **진행 상태**만. 파일 경로·API 엔드포인트·클래스명은 코드 스캔으로 복구되므로 담지 않는다.

```json
"implementation": {
  "steps": [
    { "what": "짧은 작업 단위", "status": "todo" }
  ]
}
```

- `status`: `todo | in_progress | done | blocked`
- `blocked`인 step은 `"blocker": "사유"` 추가
- `done`인 step은 `"commit": "해시"` 추가 가능 (선택)
- **순서는 배열 위치**. 인덱스 필드 없음

### 한 번만 결정되는 것과 진화하는 것

- 첫 구현 시작 시 plan.features를 보고 구체 build unit으로 쪼개서 `steps` 생성
- 구현 도중 step **추가는 자유**. 재정렬·삭제는 **커밋 전 step 한정** (커밋된 step 불변성은 §4.5 참조). plan과 달리 stable contract 아님
- 사용자에게 steps 초안을 보여주고 합의 받은 뒤 코딩 시작 (사전 점검 게이트)

## 실행 모드

| 모드 | 플래그 | feature 완료 후 | 커밋 |
|------|--------|-----------------|------|
| **단계별 (기본)** | 없음 | 변경 요약 보고 → 멈춤 | 사용자 지시 시 |
| **일괄** | `--all` | 자동으로 다음 feature 진행 | feature 완료 시 자동 커밋 |

`--all`은 사용자 리뷰가 없으므로 plan이 매우 구체적인 경우에만 권장. 빌드 실패, plan 전제 오류 발견 시 즉시 멈추고 보고.

## 입력 파싱

`$ARGUMENTS`에서 `--all` 플래그 + feature id(선택) 파싱. feature id 생략 시 `progress/`에서 `"TODO"`가 남은 feature를 자동 선택. 여러 개면 AskUserQuestion으로 선택.

```
/implement                    # 기본 모드, 자동 선택, 첫 TODO feature 1개 구현
/implement word-karaoke       # 기본 모드, feature id 지정
/implement --all              # 일괄 모드, 모든 TODO 연속 수행
```

## 구현 전 탐색

**목적**: 새로 만드는 게 아니라 **기존 패턴에 편입**. 방법론·체크리스트·깊이 기준은 [references/exploration.md](references/exploration.md) 참조.

### 언제 탐색하는가 (두 시점)

| 시점 | 목표 | 결과물 |
|---|---|---|
| **steps 생성 전** (§2.a.1) | feature가 올라탈 큰 그림 — 레이어 구조·도메인 위치·의존 패턴 | steps 초안에 "기존 X 패턴 따름" 주석 |
| **각 step 구현 전** (§3.1) | 그 step이 모방할 **구체 파일 1~2개** 특정 | 모방 대상 파일 경로 (머릿속) |

시점별로 찾는 대상이 다르다. 전자는 "어떤 패턴이 있나", 후자는 "이 step에 똑같이 쓸 레퍼런스 어느 파일인가".

### 호출 규칙 요약

- **가설 먼저**: "이 기능은 ~하므로 ~패턴이 있을 것". 가설 없는 탐색 금지
- **상한**: 한 시점당 읽는 파일 ≤ 5, Grep ≤ 5. 초과하면 Agent(Explore) 위임
- **멈춤 조건**: 가설 확인 / 유사 패턴 없음 결론 / 상한 도달
- **상세**: references/exploration.md

## 실행 절차

### 1. Plan 읽기

1. `progress/{feature-id}.json` 읽기. 파일 없으면 중단 후 보고
2. **종료 조건**: 모든 `features[].status`가 `"DONE"`이면 완료 상태. 실행 중단하고 사용자에게 알림
3. `CLAUDE.md`, `.claude/rules/*.md` 짧게 훑어 컨벤션 파악

### 2. steps 준비

**(a) steps가 없거나 비어 있으면 — 초기 생성**

1. 관련 코드를 스캔(Glob/Grep/Read)해 기존 모듈·패턴·의존성 파악
2. 현재 처리할 feature를 만족시키는 **구체 build unit**으로 steps 초안을 만든다
   - 한 step = 1~수 커밋 분량의 작업 단위
   - 파일 경로는 최소한으로만 (step의 "what"에 암시적으로). 전체 manifest 작성 금지
3. 초안을 사용자에게 보여주고 합의 받음. 수정 지시 반영 후 재확인
4. 합의되면 `implementation.steps`에 write. 모든 step `status: "todo"`

**(b) steps가 이미 있으면 — 세션 재개**

1. 상태 요약: done N개 / todo N개 / blocked N개, 다음 todo step 보고
2. 사용자 확인 없이 다음 `todo` step부터 바로 시작 가능 (단, 사용자가 질문하면 답)

### 3. 현재 step 구현

현재 step의 status를 `in_progress`로 갱신한 뒤:

1. step의 `what`을 만족시키는 **최소 변경**을 파악 — 관련 파일 탐색, 기존 패턴 확인
2. 코드 작성 + 필요 시 테스트 작성
3. 해당 언어/프레임워크의 기본 검증 실행 (빌드, 타입체크, 테스트). 실패하면 수정해서 재실행
4. 3회 연속 같은 원인으로 실패하면 step status를 `blocked`로 바꾸고(`"blocker"` 사유 포함) 사용자에게 보고
5. **자가 리뷰** (테스트 통과 후, §4로 가기 전). 이번 step 범위의 변경만 대상. 체크리스트 읽기가 아니라 각 항목 **나열→판정**:

   **범위 점검**
   - `git diff --stat` 으로 이번 step에서 변경된 파일을 나열하고, 각 파일이 step의 `what`에 직접 기여하는가 한 줄 판정. "하는 김에" 변경이 섞였으면 되돌리거나 별도 step으로 분리

   **어플리케이션 코드** (변경된 production 파일)
   - 새 public 함수·클래스 이름이 기존 컨벤션과 일치하는가 (탐색에서 특정한 모방 대상과 대조)
   - 에러 처리·경계값이 유사 기존 코드와 동일 수준인가 (임의 silent catch·TODO 잔존 금지)
   - plan 범위 밖 추상화·가상 요구사항 방어 코드가 섞였는가 → 제거
   - 주석이 WHY가 아닌 WHAT을 중계하는가 → 제거

   **테스트 코드** (이 step에서 추가·변경된 테스트)
   - step의 `what`이 기술하는 **관측 동작**을 검증하는가 (내부 메서드 호출 횟수만 검증하는 약한 테스트 금지)
   - 어써션이 실제 결과를 확인하는가 ("에러 안 남" happy-path-only 금지)
   - 기존 테스트 관용(Base 클래스·fixture·mock 전략)을 따랐는가
   - 테스트 이름이 시나리오를 명확히 전달하는가

   수정이 발생하면 코드 고치고 테스트 재실행 → 통과 후 이 단계 재검증. 통과해야 §4로.

**테스트 작성 여부**: step의 `what`이 코드 동작을 기술하면(상태 전환, 출력값, 데이터 흐름) 테스트를 쓴다. 프로젝트에 테스트 컨벤션이 있으면 따르고, 없으면 프로젝트 관용을 따른다.

**plan 범위 판단**:
- step 완수에 직접 필요한 리팩토링/헬퍼 추가 → 범위 내
- "하는 김에" 주변 정리, 무관한 개선 → 범위 밖

### 4. step 완료 처리

step 작업이 끝나면:

1. step의 `status`를 `"done"`으로 갱신 (commit 후면 `"commit"` 해시 추가)
2. **현재 feature의 모든 step이 done이면** → feature 완료 플로우(5)로
3. **현재 feature의 남은 step이 있으면**:
   - **기본 모드**: step 변경 요약을 짧게 보고한 뒤 **반드시 `AskUserQuestion`을 호출**해 다음 행동을 묻는다. 평문 "대기 중"으로 끝내지 않는다. 옵션:
     - "다음 step" — 이어서 다음 todo step 구현 (3 반복)
     - "커밋" — §6로 가서 커밋만 수행 후 다시 이 질문
     - "커밋하고 다음 step" — §6 커밋 → 다음 todo step 구현
     - "수정 필요" — 사용자가 피드백을 준다 (자유 입력으로 대체)
     - "중단" — 현재 상태 저장 후 종료
   - **`--all` 모드**: 질문 없이 바로 다음 todo step으로 3 반복

### 4.5 step 불변성 원칙

**커밋된 step은 immutable.** 사후 발견된 하자·버그·리팩토링은 기존 step을 열지 말고 새 step으로 추가한다.

- **커밋 전 (현재 step 작업 중)**: 셀프리뷰·피드백으로 나온 수정은 같은 step에 흡수해 함께 커밋. steps 배열 변경 없음.
- **커밋 후 (step `done` + commit 해시)**: 해당 step의 `what`·`commit`·파일 범위는 건드리지 않는다. 추가 작업은 새 step을 `implementation.steps`에 삽입.
- **새 step 삽입 순서**: 아직 `todo`·`in_progress`인 구간에서는 의존 관계에 맞게 자유롭게 재배치 가능. 이미 `done`인 step의 배열 위치는 그대로 둔다.
- **예외**: plan 전제 자체가 틀린 경우는 중단하고 `/plan`으로 돌아간다 (신규 step으로 덧붙이지 않는다).

### 5. feature 완료 보고 + 대기 (기본 모드)

> `--all` 모드는 이 단계 건너뛰고 6(자동 커밋) → feature status DONE → 다음 feature

현재 feature의 모든 step이 done이면 다음을 보고한다:

1. 수행한 feature — `what` 인용
2. 변경된 파일 — new / modified / deleted
3. 주요 결정 — 1~3줄
4. 검증 결과 — 테스트/빌드 실행 결과
5. 남은 feature 수

보고 직후 **반드시 `AskUserQuestion`을 호출**해 다음 행동을 묻는다. 평문 "대기 중"으로 끝내지 않는다. 옵션:

- "다음 feature" — feature `status` DONE 갱신 → 다음 feature의 §2로 (커밋 없이)
- "커밋" — §6 커밋만 수행 → 다시 이 질문
- "커밋하고 다음 feature" — §6 커밋 → `status` DONE → 다음 feature §2로
- "수정 필요" — 사용자가 피드백을 준다 (자유 입력으로 대체)
- "중단" — 현재 상태 저장 후 종료

자유 입력 응답이면 지시대로 수행 후 §3 재보고. 애매하면 다시 질문한다 — 추측해서 진행하지 않는다.

### 6. 커밋

트리거:
- **기본 모드**: 사용자가 명시적으로 지시했을 때만
- **`--all` 모드**: 각 feature 구현 끝나면 자동

절차:
1. `git status`로 변경 확인
2. `git add`로 현재 feature 범위 파일만 스테이지. 무관한 변경이 섞여 있으면 기본 모드는 확인, `--all`은 멈추고 보고
3. 커밋 메시지 초안 — feature의 `what`을 제목으로. **"왜" 비자명한 결정이 있었으면 본문에 포함** (plan.notes.decisions가 없는 영역의 HOW 결정 근거)
4. 기본 모드는 초안 승인 받음. `--all`은 그대로 사용
5. `git commit` → hash 보고
6. `--no-verify` 금지. hook 실패 시 원인 파악 후 재시도

### 7. feature status 갱신 + 다음 feature

feature가 "DONE" 확정되면(사용자 OK 또는 `--all` 커밋 직후):

1. `progress/{feature-id}.json`의 해당 feature `status`를 `"TODO"` → `"DONE"`
2. `implementation.steps`는 남겨둔다 — 감사·회고용
3. 남은 `"TODO"` 있으면 다음 feature의 2(steps 준비)로
4. 모두 `"DONE"`이면 완료 보고하고 종료

## `implementation.steps` 작성 가이드

### 좋은 step 예시

- "DDL + Entity + Repository"
- "외부 API 클라이언트 + 응답 파서"
- "통합 테스트 (외부 API mock)"

### 나쁜 step 예시

- "`domain/foo/BarEntity.<ext>` 작성" — 특정 파일 경로 노출, 코드가 정답
- "retry 로직 추가" — 너무 구체, 상위 step의 일부
- "계획 수립" — 메타 step

### 갱신 원칙

- **step 시작 시**: `in_progress`로
- **step 완료 시**: `done`으로, 필요 시 `commit` 해시 추가
- **막힐 때**: `blocked` + `blocker` 사유
- **plan과 다르게 쪼개야 한다고 판단되면**: 사용자에게 알리고 합의 후 steps 재작성

### steps 재작성 판단 기준 (관측 신호)

다음 중 하나라도 관측되면 재작성을 사용자에게 제안한다:

- 한 step의 `in_progress` 기간이 **한 세션(약 반나절)을 넘길 것으로 예상**
- 한 step에서 **커밋을 3개 이상** 끊어야 의미가 맞음 (= step이 너무 큼)
- 두 step이 같은 파일군을 반복 수정 — 경계가 잘못 그어짐 (병합 또는 재분할)
- step의 `what`이 구현 중 관측한 실제 작업과 어긋남 (예: "API 클라이언트"로 시작했는데 실제로는 DTO 스키마 설계가 본질)
- 한 step이 `blocked` 3회 이상 — 선행 조건이 빠진 신호

### step 추가 시나리오

구현 중·구현 후에 새 작업이 필요하다고 판단되는 경우. **공통 원칙**: 임의 추가 금지. 사용자 합의 후에만 steps 배열 수정.

**(A) 구현 도중 plan 구멍 발견 — 진행 중 step에 추가 필요**

현재 step을 끝내기 위해 새 작업이 필수인 경우(예: 필요한 helper가 없어 먼저 만들어야 함).

1. 현재 step을 `blocked`로 전환하고 `blocker`에 사유 기록
2. 새 step 초안을 현재 step **앞**에 삽입(전제 관계)하는 안을 사용자에게 보고
3. 합의되면 steps 배열 재작성 → 새 step부터 §3 진행 → 완료 후 기존 step으로 복귀(`in_progress`로 되돌림)

**(B) 구현 도중 plan 구멍 발견 — 현재 step과 독립, 후속으로 처리 가능**

현재 step 완수에는 지장 없지만 feature 내 다른 필요 작업이 드러난 경우.

1. 현재 step 그대로 §3 완료
2. §4 step 완료 처리에서 사용자에게 "신규 step 추가 안" 보고 → 합의 후 todo 배열 끝에 삽입
3. 이어서 다음 todo로 진행

**(C) feature 완료 후 리팩토링·버그픽스 필요**

모든 feature의 step이 `done`, §5 보고까지 끝난 상태에서 추가 작업이 드러난 경우.

판단 기준:
- **같은 feature 범위 내 + 플랜 의도의 미완성**(예: feature의 `what`이 커버하는 동작인데 누락·버그) → feature `status`를 `TODO`로 되돌리고, `implementation.steps`에 새 step 추가 후 §3부터 재진행. 사용자 합의 필수
- **같은 feature 범위 밖 리팩토링/주변 정리** → 현재 plan에 **새 feature** 추가가 맞으면 `/plan`으로 돌아가 `features`에 append. 범위가 크면 **별도 plan** 생성
- **다른 feature 구현 중 발견된 회귀·버그** → 회귀를 유발한 feature로 돌아가 (A)/(B) 처리

**(D) plan 전제가 틀렸다고 판단 — steps 대폭 변경 필요**

§4.5 예외 조항 참조. 중단하고 `/plan`으로 돌아간다.

1. 현재 작업 중단하고 사용자에게 보고
2. `/plan`으로 돌아가 `goal`/`features`/`notes` 재정렬 → plan 합의 후 implement 재진입

**공통 금지**
- 사용자 합의 없이 steps 배열 수정
- 범위 밖 작업을 "하는 김에" 현재 step에 끼워 넣기
- `status: DONE` 처리된 feature에 몰래 step 추가 (감사 추적 깨짐 — 반드시 `TODO`로 되돌리고 합의)

## 하지 않는 것

- 기본 모드에서 feature 1개 끝난 뒤 자동으로 다음 feature 진행
- 기본 모드에서 자동 커밋
- Plan 범위 밖 리팩토링·코드 정리
- 컨벤션 외 주관적 개선
- 자동 evaluator 호출 (평가는 사용자)
- feature 순서 임의 변경 (배열 순서 = 구현 순서)
- `implementation.steps`에 파일 manifest·API 엔드포인트·클래스 시그니처 기록 (코드가 정답)
- plan의 `goal`·`features`·`notes` 수정 (plan 전제가 틀리면 중단 후 `/plan`으로 돌아감)
